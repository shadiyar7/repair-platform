module Api
  module V1
    module Integrations
      class IdocsController < ApplicationController
        # iDocs scenario (per PDF documentation):
        # PREPARE: upload blob → create doc → create route → content-to-sign (returns downloadLink + idempotencyTicket)
        #          → download content file → base64 encode → return to frontend for NCALayer
        # SIGN: upload CMS signature blob → save_signature (with idempotencyTicket)

        def prepare
          order = Order.find(params[:id])
          client = IDocs::Client.new
          director_id = IDocs::Client::DIRECTOR_EMPLOYEE_ID

          # 1. Generate contract PDF
          signer_service = IDocs::ContractSigner.new(order)
          pdf_data = signer_service.generate_contract_pdf
          file_path = Rails.root.join("tmp", "contract_order_#{order.id}.pdf")
          File.binwrite(file_path, pdf_data)

          # 2. Upload PDF blob to iDocs
          blob_response = client.upload_file(file_path.to_s)
          Rails.logger.info "iDocs blob upload response: #{blob_response}"
          blob_id = blob_response.dig("response", "blobId") || blob_response.dig("response", "id")
          raise "Failed to get blobId from iDocs upload: #{blob_response}" if blob_id.blank?

          # 3. Create document in iDocs
          metadata = {
            name: "Договор поставки №CTR-#{Time.now.year}-#{order.id}",
            number: "CTR-#{Time.now.year}-#{order.id}",
            date: Time.now.to_i,
            group: "Purchase",
            author_id: director_id
          }
          Rails.logger.info "iDocs create_document payload: #{metadata.merge(blob_id: blob_id)}"
          doc_response = client.create_document(metadata, blob_id)
          Rails.logger.info "iDocs create_document response: #{doc_response}"
          document_id = doc_response["id"] || doc_response.dig("response", "id")
          raise "Failed to get documentId from iDocs: #{doc_response}" if document_id.blank?

          # 4. Create quick route to client (BEFORE signing, per iDocs scenario)
          requisite    = order.company_requisite
          client_bin   = requisite&.bin
          client_email = order.user&.email

          if client_bin.present? && client_email.present?
            Rails.logger.info "iDocs creating quick route: doc=#{document_id}, bin=#{client_bin}, email=#{client_email}"
            client.create_quick_route(document_id, director_id, client_bin, client_email)
          else
            Rails.logger.warn "iDocs: skipping quick route — client BIN or email missing"
          end

          # 5. Get content-to-sign metadata (returns downloadLink + idempotencyTicket)
          sign_meta = client.get_content_to_sign(document_id, director_id)
          Rails.logger.info "iDocs content-to-sign meta: #{sign_meta.inspect}"

          download_link    = sign_meta["downloadLink"]
          idempotency_ticket = sign_meta["idempotencyTicket"]
          raise "No downloadLink in content-to-sign response: #{sign_meta}" if download_link.blank?

          # 6. Download the content-to-sign file and base64 encode it for NCALayer
          content_bytes = client.download_sign_content(download_link)
          content_to_sign = Base64.strict_encode64(content_bytes)
          Rails.logger.info "iDocs content-to-sign: downloaded #{content_bytes.bytesize} bytes, base64 length=#{content_to_sign.length}"

          # 7. Save document_id on order
          order.update(idocs_document_id: document_id, idocs_status: 'pending_director_signature')

          render json: {
            success: true,
            documentId: document_id,
            contentToSign: content_to_sign,
            idempotencyTicket: idempotency_ticket
          }
        rescue => e
          Rails.logger.error "iDocs prepare error: #{e.message}\n#{e.backtrace.first(5).join("\n")}"
          render json: { error: e.message }, status: 500
        end

        # Upload and save director's CMS signature
        def sign
          order = Order.find(params[:id])
          signature          = params[:signature]
          document_id        = params[:documentId] || order.idocs_document_id
          idempotency_ticket = params[:idempotencyTicket]

          return render json: { error: "Signature is missing" }, status: 400 if signature.blank?
          return render json: { error: "Document ID is missing" }, status: 400 if document_id.blank?

          client = IDocs::Client.new
          director_id = IDocs::Client::DIRECTOR_EMPLOYEE_ID

          # 1. Upload signature blob
          sig_blob_response = client.upload_signature(signature)
          Rails.logger.info "iDocs upload_signature response: #{sig_blob_response}"
          sig_blob_id = sig_blob_response.dig("response", "blobId") ||
                        sig_blob_response.dig("response", "id") ||
                        sig_blob_response["blobId"]
          raise "Failed to upload signature to iDocs: #{sig_blob_response}" if sig_blob_id.blank?

          # 2. Save signature on document (idempotencyTicket required by iDocs API)
          save_result = client.save_signature(document_id, director_id, sig_blob_id, idempotency_ticket)
          Rails.logger.info "iDocs save_signature response: #{save_result.inspect}"

          order.update(idocs_status: 'sent_to_client')
          render json: {
            success: true,
            message: "Документ подписан директором и отправлен клиенту",
            idocs_status: order.idocs_status
          }
        rescue => e
          Rails.logger.error "iDocs sign error: #{e.message}\n#{e.backtrace.first(5).join("\n")}"
          render json: { error: e.message }, status: 500
        end
      end
    end
  end
end
