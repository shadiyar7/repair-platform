module Api
  module V1
    module Integrations
      module OneC
        class PaymentsController < ApplicationController
          skip_before_action :authenticate_user!, only: [:verified]
          skip_before_action :verify_authenticity_token, only: [:verified], raise: false
          
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
            url = "https://f577a0f8677a.ngrok-free.app/Integration/hs/int/post_payments"
            username = "администратор"
            password = "" # Empty password

            # Sample payload structure as requested
            payload = {
              "binn": "881204301051",
              "ID": "00001",
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
                  data = JSON.parse(response.body)
                  
                  # Look for 'image' first, then others
                  invoice_code = data['image'] || data['base64'] || data['invoice_base64'] || data['file']
                  
                  if invoice_code.present?
                     # Update Order #1 as per user's hardcoded test scenario
                     test_order = Order.find_by(id: 1)
                     if test_order
                        test_order.update(invoice_base64: invoice_code)
                        Rails.logger.info "Saved invoice_base64 (image) to Order #1"
                     end
                  end
                  
                  # Respond to frontend with success and snippet of data
                  render json: { 
                    message: "Request sent to 1C successfully", 
                    "1c_status" => data['status'],
                    image_length: invoice_code&.length,
                    note: "Base64 saved to Order #1"
                  }, status: :ok
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
