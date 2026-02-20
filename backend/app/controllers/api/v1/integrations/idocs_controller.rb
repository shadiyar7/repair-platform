module Api
  module V1
    module Integrations
      class IdocsController < ApplicationController
        # before_action :authenticate_user! # Enable in prod

        # Step 1: Prepare document for signing
        # - Generates contract PDF
        # - Uploads PDF to iDocs
        # - Creates document in iDocs (as Director / Первый руководитель)
        # - Gets content-to-sign (hash) from iDocs to pass to NCALayer
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
          # iDocs returns { response: { blobId: '...', fileName: '...' } }
          blob_id = blob_response.dig("response", "blobId") || blob_response.dig("response", "id")
          raise "Failed to get blobId from iDocs upload: #{blob_response}" if blob_id.blank?

          # 3. Create document in iDocs on behalf of Director
          metadata = {
            name: "Договор поставки №CTR-#{Time.now.year}-#{order.id}",
            number: "CTR-#{Time.now.year}-#{order.id}",
            date: Time.now.strftime("%Y-%m-%dT%H:%M:%S"),
            author_id: director_id
          }
          Rails.logger.info "iDocs create_document payload: #{metadata.merge(blob_id: blob_id)}"
          doc_response = client.create_document(metadata, blob_id)
          Rails.logger.info "iDocs create_document response: #{doc_response}"
          # iDocs may return id under 'id' or 'documentId'
          document_id = doc_response.dig("response", "id") || doc_response.dig("response", "documentId")
          raise "Failed to get documentId from iDocs create_document: #{doc_response}" if document_id.blank?

          # 4. Get content-to-sign (hash/data) for NCALayer
          sign_content_response = client.get_content_to_sign(document_id, director_id)
          content_to_sign = sign_content_response.dig("response")
          # content_to_sign is the base64 data that NCALayer needs to sign

          # 5. Save document_id on order for next step
          order.update(idocs_document_id: document_id, idocs_status: 'pending_director_signature')

          render json: {
            success: true,
            documentId: document_id,
            contentToSign: content_to_sign
          }
        rescue => e
          Rails.logger.error "iDocs prepare error: #{e.message}\n#{e.backtrace.first(5).join("\n")}"
          render json: { error: e.message }, status: 500
        end

        # Step 2: Save director's signature and send document to client for signing
        # - Uploads CMS signature from NCALayer to iDocs
        # - Saves signature on the document
        # - Creates quick-route to send document to client
        def sign
          order = Order.find(params[:id])
          signature = params[:signature]   # base64 CMS from NCALayer
          document_id = params[:documentId] || order.idocs_document_id

          return render json: { error: "Signature is missing" }, status: 400 if signature.blank?
          return render json: { error: "Document ID is missing" }, status: 400 if document_id.blank?

          client = IDocs::Client.new
          director_id = IDocs::Client::DIRECTOR_EMPLOYEE_ID

          # 1. Upload signature blob to iDocs
          sig_blob_response = client.upload_signature(signature)
          sig_blob_id = sig_blob_response.dig("response", "id")
          raise "Failed to upload signature to iDocs: #{sig_blob_response}" if sig_blob_id.blank?

          # 2. Save signature on document
          client.save_signature(document_id, director_id, sig_blob_id)

          # 3. Create quick-route to send to client for their signature
          # Client details come from order's company_requisite
          requisite = order.company_requisite || order.user
          client_bin   = requisite.respond_to?(:bin) ? requisite.bin : nil
          client_email = requisite.respond_to?(:email) ? requisite.email : order.user&.email

          if client_bin.present? && client_email.present?
            client.create_quick_route(document_id, director_id, client_bin, client_email)
            order.update(idocs_document_id: document_id, idocs_status: 'sent_to_client')
            message = "Документ подписан директором и отправлен клиенту (#{client_email}) для подписания"
          else
            # Can't send to client without BIN/email — mark as signed_by_us only
            order.update(idocs_document_id: document_id, idocs_status: 'signed_by_us')
            message = "Документ подписан директором. Не хватает BIN или email клиента для отправки."
          end

          render json: { success: true, message: message, idocs_status: order.idocs_status }
        rescue => e
          Rails.logger.error "iDocs sign error: #{e.message}\n#{e.backtrace.first(5).join("\n")}"
          render json: { error: e.message }, status: 500
        end
      end
    end
  end
end
