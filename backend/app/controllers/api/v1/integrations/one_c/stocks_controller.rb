module Api
  module V1
    module Integrations
      module OneC
        class StocksController < ApplicationController
          skip_before_action :authenticate_user!, raise: false
          skip_before_action :verify_authenticity_token, raise: false


          # GET /api/v1/integrations/one_c/stocks
          def index
            # Filter by warehouse_id (external_id_1c)
            # If user is warehouse manager, enforce their warehouse
            if current_user&.warehouse
               warehouse_id = current_user.warehouse.external_id_1c
               warehouse = current_user.warehouse
            else
               warehouse_id = params[:warehouse_id] || "000000001"
               warehouse = Warehouse.find_by(external_id_1c: warehouse_id)
               warehouse ||= Warehouse.first
            end

            unless warehouse
              Rails.logger.warn "⚠️ [Stocks#index] Warehouse not found for ID: #{warehouse_id}"
              render json: { items: [], last_synced_at: nil }
              return
            end
            
            # Enqueue sync job
            SyncStocksJob.perform_later(warehouse.id)
            Rails.logger.info "⚡️ [Stocks#index] Enqueued SyncStocksJob for warehouse #{warehouse.name} (#{warehouse.external_id_1c})"

            # Get stocks for this specific warehouse
            stocks = warehouse.warehouse_stocks
            
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
                # Only include if manually added UIDs exist. 1C quantity is ignored for inclusion.
                has_uids = product.uids.present? && product.uids.is_a?(Array) && product.uids.size > 0
                
                if has_uids
                  items << {
                    id: product.id,
                    sku: product.sku,
                    nomenclature_code: product.nomenclature_code,
                    name: product.name,
                    category: product.category,
                    image: product.image_url,
                    price: product.price,
                    characteristics: product.characteristics,
                    quantity: stock.quantity.to_f,
                    synced_at: stock.synced_at,
                    warehouse_nomenclature_name: stock.nomenclature_name,
                    uids: product.uids
                  }
                end
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
            # Log Raw Body for extreme debugging - avoid encoding issues
            raw_body = request.body.read
            safe_body = raw_body.force_encoding('UTF-8').scrub
            Rails.logger.info "📥 [1C PUSH] Raw Body: #{safe_body.truncate(500)}"
            request.body.rewind # Rewind so standard param parsing still works

            warehouse_id = params[:warehouse_id_1c] || params.dig(:stock, :warehouse_id_1c)
            items = params[:items] || params.dig(:stock, :items)

            Rails.logger.info "📥 [1C PUSH] Incoming sync for Warehouse ID: #{warehouse_id}. Items count: #{items&.size || 0}"

            if warehouse_id.blank? || items.nil?
              Rails.logger.error "❌ [1C PUSH] Invalid payload: warehouse_id_1c=#{warehouse_id.inspect}, items_nil=#{items.nil?}"
              render json: { error: 'Invalid payload' }, status: :bad_request
              return
            end

            warehouse = Warehouse.find_by(external_id_1c: warehouse_id)

            unless warehouse
              Rails.logger.error "❌ [1C PUSH] Warehouse not found: #{warehouse_id}"
              render json: { error: "Warehouse with external_id_1c #{warehouse_id} not found" }, status: :not_found
              return
            end

            processed_count = 0

            ActiveRecord::Base.transaction do
              synced_now = Time.current
              warehouse.update!(last_synced_at: synced_now)

              items.each do |item|
                # Handle both symbol and string keys
                item = item.with_indifferent_access if item.respond_to?(:with_indifferent_access)
                
                code = item[:nomenclature_code]
                next if code.blank?

                stock = warehouse.warehouse_stocks.find_or_initialize_by(nomenclature_code: code)
                
                stock.nomenclature_name = item[:nomenclature_name] if item[:nomenclature_name].present?
                stock.quantity = item[:quantity].to_f
                stock.synced_at = synced_now
                
                # Try to link to a product if possible, for backward compatibility
                # product = Product.find_by(nomenclature_code: code)
                # stock.product_sku = product.sku if product
                
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
             # Use production URL
             one_c_url = ENV.fetch('ONE_C_API_URL', "https://1cstart.itsheff.cloud/komandeersykixo/hs/int/get_stocks")
             url = URI(one_c_url)
             
             begin
               https = Net::HTTP.new(url.host, url.port)
               https.use_ssl = true
               
               request = Net::HTTP::Get.new(url)
               request["Content-Type"] = "application/json"
               request.basic_auth("integration", "Aa123456!!")
               
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
