module Api
  module V1
    module Integrations
      module OneC
        class PaymentsController < ApplicationController
          skip_before_action :authenticate_user!, only: [:verified]
          
          # POST /api/v1/integrations/one_c/payment_verified
          # Payload: { "Id": 1, "status": true }
          def verified
            order_id = params[:Id]
            status = params[:status]

            if order_id.blank?
              return render json: { code: 400, message: "Missing Id" }, status: :bad_request
            end

            order = Order.find_by(id: order_id)
            
            if order
              if status.to_s == 'true' || status == true
                order.update(is_verified: true)
                render json: { code: 200, message: "Success" }
              else
                 # If status is false, do we unverify? Or just log? 
                 # For now, let's assume we matches the requirement "returns success"
                 render json: { code: 200, message: "Status is false, no action taken but acknowledged" }
              end
            else
              render json: { code: 404, message: "Order not found" }, status: :not_found
            end
          end

          # POST /api/v1/integrations/one_c/test_trigger
          # Triggered by frontend button "Test 1C"
          def test_trigger
            # Hardcoded 1C Endpoint and Credentials as requested
            url = "https://f577a0f8677a.ngrok-free.app/Integration/hs/int/POST_payments"
            username = "администратор"
            password = "" # Empty password

            # Sample payload structure
            payload = {
              "binn": "881204301051",
              "ID": 1,
              "companyName": "MOTIVE",
              "warehouseId": "000000001",
              "totalPrice": 800,
              "items": [
                {
                  "nomenclature_code": "00000000181",
                  "quantity": 50,
                  "price": 4
                },
                {
                  "nomenclature_code": "00000000190",
                  "quantity": 120,
                  "price": 5
                }
              ]
            }

            begin
              uri = URI(url)
              http = Net::HTTP.new(uri.host, uri.port)
              http.use_ssl = true
              
              request = Net::HTTP::Post.new(uri)
              request.basic_auth(username, password)
              request.content_type = 'application/json'
              request.body = payload.to_json

              response = http.request(request)

              Rails.logger.info "1C Test Trigger Response: #{response.code} - #{response.body}"

              if response.code.to_i >= 200 && response.code.to_i < 300
                begin
                  # Parse 1C response
                  # Assuming JSON format: { "invoice_base64": "..." } or similar
                  # User asked to save it to the field directly.
                  # Since we don't know the exact key, let's look for likely candidates or just save the first large string.
                  # But typically 1C returns a structured JSON.
                  # Let's try to parse and find a field "invoice_base64" or "base64" or "file".
                  # If not found, we might need to debug. For now, let's try to grab 'invoice_base64'.
                  
                  data = JSON.parse(response.body)
                  # Try to find the base64 string. 
                  # ADJUST THIS KEY based on actual 1C response structure.
                  # For now, I will look for 'base64' or 'invoice' or 'data'.
                  invoice_code = data['base64'] || data['invoice_base64'] || data['file'] || data['data']
                  
                  if invoice_code.present?
                     # Update Order #1 as per user's hardcoded test scenario
                     test_order = Order.find_by(id: 1)
                     if test_order
                        test_order.update(invoice_base64: invoice_code)
                        Rails.logger.info "Saved invoice_base64 to Order #1"
                     end
                  end
                  
                  render json: { message: "Request sent to 1C successfully", response: data }, status: :ok
                rescue => e
                  Rails.logger.error "Failed to parse 1C response: #{e.message}"
                  render json: { message: "Request sent to 1C, but failed to parse response", response: response.body }, status: :ok
                end
              else
                render json: { error: "Failed to send to 1C", code: response.code, body: response.body }, status: :bad_gateway
              end
            rescue => e
              Rails.logger.error "1C Test Trigger Error: #{e.message}"
              render json: { error: e.message }, status: :internal_server_error
            end
          end
        end
      end
    end
  end
end
