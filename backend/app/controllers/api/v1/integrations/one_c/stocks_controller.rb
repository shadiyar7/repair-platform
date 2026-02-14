module Api
  module V1
    module Integrations
      module OneC
        class StocksController < ApplicationController
          skip_before_action :authenticate_user!, raise: false
          skip_before_action :verify_authenticity_token, raise: false


          # GET /api/v1/integrations/one_c/stocks
          def index
            # Filter by warehouse_id (external_id_1c) from params, or default to "000000001" (Pavlodar)
            warehouse_id = params[:warehouse_id] || "000000001"
            
            warehouse = Warehouse.find_by(external_id_1c: warehouse_id)
            
            # If not found (e.g. invalid ID), try first one or return empty
            warehouse ||= Warehouse.first

            unless warehouse
              render json: { items: [], last_synced_at: nil }
              return
            end
            
            # Check if sync is needed (stale data > 1 hour OR never synced)
            if warehouse.last_synced_at.nil? || warehouse.last_synced_at < 1.hour.ago
               # Enqueue sync job
               SyncStocksJob.perform_later(warehouse.id)
               Rails.logger.info "Enqueued SyncStocksJob for warehouse #{warehouse.name} (#{warehouse.external_id_1c}) - Stale data"
            end

            # Get stocks for this specific warehouse
            stocks = warehouse.warehouse_stocks.where("quantity > 0")
            
            # Map stocks to Product details via nomenclature_code
            items = []
            stocks.each do |stock|
              # Try finding product by nomenclature_code first (new way)
              product = nil
              if stock.nomenclature_code.present?
                product = Product.find_by(nomenclature_code: stock.nomenclature_code)
              end
              
              # Fallback: try finding by SKU if nomenclature_code didn't match (legacy way or transition period)
              # But user said 1C sends nomenclature_code like "00001", and Product.sku is "WS-...", so they won't match directly.
              # Unless stock.product_sku stored the "00001" before? Yes it did.
              if product.nil? && stock.product_sku.present?
                  # Try to find product where its nomenclature_code matches stock.product_sku?
                  # Or where its SKU matches? 
                  # Previous logic was: Product.find_by(sku: stock.product_sku).
                  # Since stock.product_sku was holding "00001", this only worked if Product.sku was "00001".
                  # User said it wasn't working well.
              end

              # Only show if product exists, is active
              if product && product.is_active
                items << {
                  id: product.id,
                  sku: product.sku, # Show the Human Readable SKU (WS-...)
                  nomenclature_code: product.nomenclature_code, # 1C ID
                  name: product.name,
                  category: product.category,
                  image: product.image_url,
                  price: product.price,
                  characteristics: product.characteristics,
                  quantity: stock.quantity,
                  synced_at: stock.synced_at
                }
              end
            end
            
            render json: {
              warehouse: {
                name: warehouse.name,
                id: warehouse.id,
                external_id_1c: warehouse.external_id_1c
              },
              last_synced_at: warehouse.last_synced_at,
              items: items
            }
          end

          # POST /api/v1/integrations/one_c/stocks
          def update
            warehouse_id = params[:warehouse_id_1c]
            items = params[:items]

            if warehouse_id.blank? || items.nil?
              render json: { error: 'Invalid payload' }, status: :bad_request
              return
            end

            warehouse = Warehouse.find_by(external_id_1c: warehouse_id)

            unless warehouse
              render json: { error: "Warehouse with external_id_1c #{warehouse_id} not found" }, status: :not_found
              return
            end

            processed_count = 0

            ActiveRecord::Base.transaction do
              synced_now = Time.current
              
              # Update Warehouse timestamp
              warehouse.update!(last_synced_at: synced_now)

              items.each do |item|
                next unless item[:nomenclature_code].present? 

                # Find by nomenclature_code instead of product_sku
                # If product_sku column was used for this before, we should start using nomenclature_code
                stock = warehouse.warehouse_stocks.find_or_initialize_by(nomenclature_code: item[:nomenclature_code])
                
                # Also fallback for existing ones? No, user wants clean start or migration?
                # Let's populate product_sku for legacy compatibility if we can find a product?
                # Actually, if we switch to nomenclature_code linking, we should stick to it.
                
                stock.quantity = item[:quantity] || 0
                stock.synced_at = synced_now
                # Also save the textual product_sku if we can find a product match?
                # Or just leave product_sku as nil/legacy?
                # Given user wants "unlinked" logic, we rely on nomenclature_code.
                
                stock.save!
                
                processed_count += 1
              end
            end

            render json: { status: 'success', processed_items: processed_count }
          rescue StandardError => e
            Rails.logger.error("1C Sync Error: #{e.message}")
            render json: { error: 'Internal Server Error during sync' }, status: :internal_server_error
          end
          # GET /api/v1/integrations/one_c/test_stocks
          # Triggered by frontend "Тест склада" button
          # Executes a raw request to 1C get_stocks to see what it returns
          def test_stocks
             warehouse_id = params[:warehouse_id] || "000000001"
             
             # Configuration
             one_c_url = "https://f577a0f8677a.ngrok-free.app/Integration/hs/int/get_stocks"
             url = URI(one_c_url)
             
             begin
               https = Net::HTTP.new(url.host, url.port)
               https.use_ssl = true
               
               request = Net::HTTP::Get.new(url)
               request["Content-Type"] = "application/json"
               request.basic_auth("администратор", "")
               
               request.body = JSON.dump({
                 "warehouse_id_1c": warehouse_id
               })
               
               response = https.request(request)
               
               render json: {
                  message: "Request to 1C get_stocks executed",
                  request_url: one_c_url,
                  warehouse_id_requested: warehouse_id,
                  response_code: response.code,
                  response_body: response.body
               }
             rescue => e
               render json: { error: e.message }
             end
          end
        end
      end
    end
  end
end
