module Api
  module V1
    module Integrations
      class IdocsController < ApplicationController
        # Scenario per iDocs PDF documentation:
        # 1. Upload PDF blob
        # 2. Create document
        # 3. Create quick route (to client, BEFORE signing)
        # 4. Get content-to-sign (hash for NCALayer)
        # 5. [Frontend] NCALayer signs → returns CMS
        # 6. Upload signature blob
        # 7. Save signature on document

        # Steps 1-4: Prepare document and route, return content-to-sign
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

          # 3. Create document in iDocs on behalf of Director
          metadata = {
            name: "Договор поставки №CTR-#{Time.now.year}-#{order.id}",
            number: "CTR-#{Time.now.year}-#{order.id}",
            date: Time.now.to_i,    # Unix timestamp (int) per iDocs API docs
            group: "Purchase",       # DocumentGroupType enum from Swagger
            author_id: director_id
          }
          Rails.logger.info "iDocs create_document payload: #{metadata.merge(blob_id: blob_id)}"
          doc_response = client.create_document(metadata, blob_id)
          Rails.logger.info "iDocs create_document response: #{doc_response}"

          # Response is NOT wrapped in 'response' key — id is at root level
          document_id = doc_response["id"] || doc_response.dig("response", "id")
          raise "Failed to get documentId from iDocs: #{doc_response}" if document_id.blank?

          # 4. Create quick route to client (per iDocs scenario, BEFORE signing)
          requisite   = order.company_requisite
          client_bin  = requisite&.bin
          client_email = requisite&.email || order.user&.email

          if client_bin.present? && client_email.present?
            Rails.logger.info "iDocs creating quick route: doc=#{document_id}, bin=#{client_bin}, email=#{client_email}"
            client.create_quick_route(document_id, director_id, client_bin, client_email)
          else
            Rails.logger.warn "iDocs: skipping quick route — client BIN or email missing (bin=#{client_bin}, email=#{client_email})"
          end

          # 5. Get content-to-sign for NCALayer
          sign_content_response = client.get_content_to_sign(document_id, director_id)
          Rails.logger.info "iDocs content-to-sign response: #{sign_content_response.class}"
          content_to_sign = sign_content_response.dig("response") || sign_content_response

          # 6. Save document_id on order
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

        # Steps 6-7: Upload and save director's CMS signature
        def sign
          order = Order.find(params[:id])
          signature   = params[:signature]
          document_id = params[:documentId] || order.idocs_document_id

          return render json: { error: "Signature is missing" }, status: 400 if signature.blank?
          return render json: { error: "Document ID is missing" }, status: 400 if document_id.blank?

          client = IDocs::Client.new
          director_id = IDocs::Client::DIRECTOR_EMPLOYEE_ID

          # 6. Upload signature blob
          sig_blob_response = client.upload_signature(signature)
          Rails.logger.info "iDocs upload_signature response: #{sig_blob_response}"
          sig_blob_id = sig_blob_response.dig("response", "blobId") ||
                        sig_blob_response.dig("response", "id") ||
                        sig_blob_response["blobId"]
          raise "Failed to upload signature to iDocs: #{sig_blob_response}" if sig_blob_id.blank?

          # 7. Save signature on the document
          client.save_signature(document_id, director_id, sig_blob_id)

          order.update(idocs_status: 'sent_to_client')
          render json: {
            success: true,
            message: "Документ подписан директором и отправлен клиенту для подписания",
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
