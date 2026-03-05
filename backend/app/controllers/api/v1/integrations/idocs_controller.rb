module Api
  module V1
    module Integrations
      class IdocsController < ApplicationController
        # ──────────────────────────────────────────────────────────────────────
        # PRODUCTION iDocs v1 sign flow:
        #
        #   PREPARE (director side):
        #     1. Generate contract PDF
        #     2. Return PDF as base64 to frontend for NCALayer signing
        #        Frontend uses NCALayer: createCMSSignatureFromBase64(sha256(pdf))
        #
        #   SIGN (director confirms):
        #     3. Receive CMS signature from frontend
        #     4. POST /api/v1/ExternalDocumentFromFiles — creates doc + director signs + sends to client
        #     5. Poll WorkflowInfo for real documentId
        #     6. Download PrintForm and persist signed PDF
        #     7. Advance order state → pending_signature (client needs to sign)
        #
        #   CLIENT_SIGN (client side, called via smart link or client portal):
        #     8. Return document PDF + WorkflowInfo for client NCALayer signing
        #     9. Receive CMS from client
        #    10. POST /api/v1/ExternalDocuments/SignInboxDocument
        # ──────────────────────────────────────────────────────────────────────

        # PREPARE: returns the PDF bytes as base64 for NCALayer and order metadata
        # Frontend must hash (SHA256) + sign with NCALayer, then call /sign
        def prepare
          order = Order.find(params[:id])

          # Generate contract PDF
          pdf_data = Pdf::ContractGenerator.new(order).generate
          pdf_base64 = Base64.strict_encode64(pdf_data)
          pdf_sha256 = Digest::SHA256.hexdigest(pdf_data)

          Rails.logger.info "iDocs prepare: order=#{order.id} pdf_size=#{pdf_data.bytesize}"

          # Save temp state on order
          order.update(idocs_status: 'pending_director_signature')

          render json: {
            success:     true,
            pdfBase64:   pdf_base64,
            pdfSha256:   pdf_sha256,
            documentName:   "Договор поставки №#{order.contract_number || "CTR-#{Time.now.year}-#{order.id}"}",
            documentNumber: order.contract_number || "CTR-#{Time.now.year}-#{order.id}"
          }
        rescue => e
          Rails.logger.error "iDocs prepare error: #{e.message}\n#{e.backtrace.first(5).join("\n")}"
          render json: { error: e.message }, status: 500
        end

        # SIGN: director sends CMS signature from NCALayer.
        # Creates the document in iDocs (with director signature inline), sends to client.
        def sign
          order     = Order.find(params[:id])
          signature = params[:signature]  # base64 CMS from NCALayer

          return render json: { error: "Signature is missing" }, status: 400 if signature.blank?

          client = IDocs::Client.new

          client_bin   = order.company_requisite&.bin || order.user&.inn
          client_email = order.user&.email
          is_individual = order.company_requisite.blank?

          Rails.logger.info "iDocs sign: order=#{order.id} client_bin=#{client_bin} client_email=#{client_email}"

          document_name   = "Договор поставки №#{order.contract_number || "CTR-#{Time.now.year}-#{order.id}"}"
          document_number = order.contract_number || "CTR-#{Time.now.year}-#{order.id}"

          # Re-generate PDF
          pdf_data = Pdf::ContractGenerator.new(order).generate

          # 1. Create document + sign inline + send to client
          create_result = client.create_and_sign_document(
            pdf_data,
            document_name,
            document_number,
            signature,
            client_bin,
            client_email,
            is_individual: is_individual
          )
          Rails.logger.info "iDocs create_and_sign result: #{create_result.inspect}"

          process_key = create_result['processKey'] || create_result['ProcessKey'] ||
                        create_result['key'] || create_result['Key'] ||
                        create_result.dig('raw')
          raise "iDocs: no processKey returned. Response: #{create_result.inspect}" if process_key.blank?

          Rails.logger.info "iDocs: got processKey=#{process_key}, polling for documentId..."

          # 2. Poll for the real document ID
          document_id = client.wait_for_document_id(process_key)
          Rails.logger.info "iDocs: resolved documentId=#{document_id}"

          # 3. Try to persist signed PDF back to order document
          begin
            signed_pdf = client.get_best_pdf(document_id)
            order.document.attach(
              io: StringIO.new(signed_pdf),
              filename: "Contract_iDocs_#{order.id}.pdf",
              content_type: 'application/pdf'
            )
            Rails.logger.info "iDocs: persisted Director-signed PDF"
          rescue => e
            Rails.logger.error "iDocs: failed to persist signed PDF: #{e.message}"
          end

          # 4. Save iDocs document ID and advance order state
          order.update!(
            idocs_document_id: document_id,
            idocs_status: 'sent_to_client'
          )
          order.director_sign! if order.may_director_sign?

          render json: {
            success:    true,
            documentId: document_id,
            processKey: process_key,
            message:    "Документ подписан директором и отправлен клиенту",
            idocs_status: order.idocs_status
          }
        rescue => e
          Rails.logger.error "iDocs sign error: #{e.message}\n#{e.backtrace.first(5).join("\n")}"
          render json: { error: e.message }, status: 500
        end

        # CLIENT_SIGN: called when the client signs the document.
        # params: signature (base64 CMS), documentId (optional, falls back to order.idocs_document_id)
        def client_sign
          order       = Order.find(params[:id])
          signature   = params[:signature]
          document_id = params[:documentId] || order.idocs_document_id

          return render json: { error: "Signature is missing" }, status: 400  if signature.blank?
          return render json: { error: "Document ID is missing" }, status: 400 if document_id.blank?

          client      = IDocs::Client.new
          employee_id = IDocs::Client::DIRECTOR_EMPLOYEE_ID  # use director; adjust if client has own employeeId

          Rails.logger.info "iDocs client_sign: order=#{order.id} doc=#{document_id}"

          sign_result = client.sign_inbox_document(document_id, employee_id, signature)
          Rails.logger.info "iDocs client_sign result: #{sign_result.inspect}"

          # Try to persist final co-signed PDF
          begin
            final_pdf = client.get_best_pdf(document_id)
            order.document.attach(
              io: StringIO.new(final_pdf),
              filename: "Contract_Signed_#{order.id}.pdf",
              content_type: 'application/pdf'
            )
            Rails.logger.info "iDocs: persisted client-signed PDF"
          rescue => e
            Rails.logger.error "iDocs: failed to persist co-signed PDF: #{e.message}"
          end

          order.update!(idocs_status: 'signed_by_client')
          order.client_sign! if order.may_client_sign?

          render json: {
            success:  true,
            message:  "Документ подписан клиентом",
            idocs_status: order.idocs_status
          }
        rescue => e
          Rails.logger.error "iDocs client_sign error: #{e.message}\n#{e.backtrace.first(5).join("\n")}"
          render json: { error: e.message }, status: 500
        end
      end
    end
  end
end
