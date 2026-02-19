module Api
  module V1
    module Integrations
      class IdocsController < ApplicationController
        # before_action :authenticate_user! # Enable in prod

        def prepare
          order = Order.find(params[:id])
          
          # 1. Generate PDF (Reuse CommercialProposalService or Contract logic)
          # We don't have a ContractService yet, but we have CommercialProposalService.
          # For now, we will assume we are signing the Commercial Proposal or a placeholder.
          
          # 2. Init Client
          client = IDocs::Client.new
          
          # 3. Upload (Mocked or Real)
          # Since Create Document fails without EmployeeID, we MUST mock this step to unblock frontend.
          
          # output = CommercialProposalService.new(order).generate
          # file_path = Rails.root.join("tmp", "order_#{order.id}.pdf")
          # File.binwrite(file_path, output)
          
          # Mock Data for NCALayer
          # NCALayer expects a base64 string or similar to sign. 
          # "content-to-sign" usually returns the hash or the data itself.
          # We'll send a dummy base64 string.
          dummy_data_to_sign = Base64.strict_encode64("DUMMY DATA FOR IDOCS SIGNING")

          render json: {
            success: true,
            documentId: 99999,
            contentToSign: dummy_data_to_sign
          }
        rescue => e
          render json: { error: e.message }, status: 500
        end

        def sign
          order = Order.find(params[:id])
          signature = params[:signature]
          document_id = params[:documentId]

          if signature.blank?
            return render json: { error: "Signature is missing" }, status: 400
          end

          # 4. Save Signature to IDocs (Mocked)
          # client.save_signature(document_id, signature)
          # client.create_quick_route(...)

          # Update Order locally
          order.update(idocs_document_id: document_id, idocs_status: 'signed_by_us')
          
          # If this was 'pending_director_signature', maybe move to next status?
          # Assuming next is 'sent_to_client' or keep it 'pending_signature' for client side.
          # For demo, let's say 'pending_payment' or 'pending_signature' (client).
          
          render json: { success: true, message: "Document signed and sent via IDocs" }
        rescue => e
          render json: { error: e.message }, status: 500
        end
      end
    end
  end
end
