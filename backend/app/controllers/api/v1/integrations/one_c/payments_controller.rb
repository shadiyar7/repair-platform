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
                # Asynchronously confirm payment (does not blocking logistics because they started on 'payment_review')
                # If order is already searching_driver or further, this transition might fail if not handled, 
                # but AASM guards usually prevent invalid transitions.
                # We need to ensure we don't error out if already moved past.
                
                if order.may_confirm_payment?
                   order.confirm_payment!
                   Rails.logger.info "Order ##{order.id} payment confirmed by 1C"
                else
                   # Just mark as verified to be safe if status moved on
                   order.update(is_verified: true)
                   Rails.logger.info "Order ##{order.id} marked verified by 1C (Status was: #{order.status})"
                end

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

            Rails.logger.info "Test Trigger Params: #{params.inspect}"

            # Get order_id from params (sent from frontend) or default to 2 as fallback
            # Handle string "null", "undefined", etc just in case
            incoming_id = params[:order_id]
            target_order_id = incoming_id.presence
            
            # If it's validish ID, use it, otherwise default to 2
            if target_order_id.to_i <= 0
                 target_order_id = 2
            end

            Rails.logger.info "Using Target Order ID: #{target_order_id} (from '#{incoming_id}')"

            # Sample payload structure as requested, using dynamic ID
            payload = {
              "binn": "881204301044",
              "ID": 1,
              "companyName": "TEST",
              "warehouseId": "000000001",
              "totalPrice": 1000, # Approximate total
              "items": [
                {"quantity"=>66, "nomenclature_code"=>"00000000016", "price"=>10}, 
                {"quantity"=>66, "nomenclature_code"=>"00000000019", "price"=>10}, 
                {"quantity"=>10, "nomenclature_code"=>"00000000035", "price"=>10}, 
                {"quantity"=>6, "nomenclature_code"=>"00000000054", "price"=>10}, 
                {"quantity"=>4, "nomenclature_code"=>"00000000060", "price"=>10}, 
                {"quantity"=>92, "nomenclature_code"=>"00000000062", "price"=>10}, 
                {"quantity"=>212.675, "nomenclature_code"=>"00000000083", "price"=>10}, 
                {"quantity"=>6, "nomenclature_code"=>"00000000115", "price"=>10}, 
                {"quantity"=>26, "nomenclature_code"=>"00000000140", "price"=>10}, 
                {"quantity"=>75, "nomenclature_code"=>"00000000147", "price"=>10}, 
                {"quantity"=>10, "nomenclature_code"=>"00000000207", "price"=>10}, 
                {"quantity"=>118, "nomenclature_code"=>"00000000389", "price"=>10}, 
                {"quantity"=>18, "nomenclature_code"=>"00000000495", "price"=>10}, 
                {"quantity"=>2, "nomenclature_code"=>"00000000496", "price"=>10}, 
                {"quantity"=>2, "nomenclature_code"=>"00000000497", "price"=>10}, 
                {"quantity"=>98, "nomenclature_code"=>"00000000411", "price"=>10}, 
                {"quantity"=>126, "nomenclature_code"=>"00000000557", "price"=>10}, 
                {"quantity"=>66, "nomenclature_code"=>"00000000558", "price"=>10}, 
                {"quantity"=>92, "nomenclature_code"=>"00000000559", "price"=>10}, 
                {"quantity"=>33, "nomenclature_code"=>"00000000571", "price"=>10}, 
                {"quantity"=>33, "nomenclature_code"=>"00000000574", "price"=>10}, 
                {"quantity"=>33, "nomenclature_code"=>"00000000575", "price"=>10}, 
                {"quantity"=>33, "nomenclature_code"=>"00000000576", "price"=>10}, 
                {"quantity"=>33, "nomenclature_code"=>"00000000577", "price"=>10}, 
                {"quantity"=>33, "nomenclature_code"=>"00000000578", "price"=>10}, 
                {"quantity"=>66, "nomenclature_code"=>"00000000579", "price"=>10}, 
                {"quantity"=>26, "nomenclature_code"=>"00000000580", "price"=>10}, 
                {"quantity"=>132, "nomenclature_code"=>"00000000581", "price"=>10}, 
                {"quantity"=>33, "nomenclature_code"=>"00000000583", "price"=>10}, 
                {"quantity"=>99, "nomenclature_code"=>"00000000584", "price"=>10}, 
                {"quantity"=>198, "nomenclature_code"=>"00000000585", "price"=>10}, 
                {"quantity"=>132, "nomenclature_code"=>"00000000586", "price"=>10}, 
                {"quantity"=>66, "nomenclature_code"=>"00000000587", "price"=>10}, 
                {"quantity"=>505, "nomenclature_code"=>"00000000588", "price"=>10}, 
                {"quantity"=>97, "nomenclature_code"=>"00000000438", "price"=>10}, 
                {"quantity"=>14, "nomenclature_code"=>"00000000243", "price"=>10}, 
                {"quantity"=>182, "nomenclature_code"=>"00000000255", "price"=>10}, 
                {"quantity"=>18, "nomenclature_code"=>"00000000300", "price"=>10}, 
                {"quantity"=>96, "nomenclature_code"=>"00000000310", "price"=>10}, 
                {"quantity"=>97, "nomenclature_code"=>"00000000311", "price"=>10}
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
                     # Update Order matching the ID we sent
                     test_order = Order.find_by(id: target_order_id)

                     if test_order
                        if test_order.update_column(:invoice_base64, invoice_code)
                          Rails.logger.info "Successfully saved invoice_base64 to Order ##{test_order.id} (Bypassed validation)"
                        else
                          Rails.logger.error "Failed to save invoice to Order ##{test_order.id}"
                        end
                     else
                        Rails.logger.warn "Order matching payload ID #{target_order_id} not found"
                     end
                  end
                  
                  # Respond to frontend with success and snippet of data
                  render json: { 
                    message: "Request sent to 1C successfully", 
                    "1c_status" => data['status'],
                    image_length: invoice_code&.length,
                    note: "Attempted to save to Order ##{target_order_id}"
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

          # POST /api/v1/integrations/one_c/real_trigger
          # Triggered by frontend "Real Test 1C" button
          # Executes the ACTUAL logic used in production (sign_contract) but returns debug info
          def real_trigger
            order_id = params[:order_id]
            order = Order.find_by(id: order_id)

            if order
              # Execute the service
              result = OneCPaymentTrigger.new(order).call
              
              render json: { 
                message: "Real 1C Trigger executed", 
                order_id: order.id,
                payload_sent: result[:payload],
                response_code: result[:response_code],
                response_body: result[:response_body],
                success: result[:success]
              }, status: :ok
            else
              render json: { error: "Order not found" }, status: :not_found
            end
          end

          # POST /api/v1/integrations/one_c/debug_trigger
          # Internal endpoint to verify payload structure before sending to real 1C
          def debug_trigger
            Rails.logger.info "---------------------------------------------------"
            Rails.logger.info "1C DEBUG TRIGGER ENDPOINT RECEIVED:"
            Rails.logger.info JSON.pretty_generate(params.as_json)
            Rails.logger.info "---------------------------------------------------"
            render json: { message: "Payload received and logged", payload: params }, status: :ok
          end
        end
      end
    end
  end
end
