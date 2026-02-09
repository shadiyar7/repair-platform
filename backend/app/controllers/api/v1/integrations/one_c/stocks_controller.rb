module Api
  module V1
    module Integrations
      module OneC
        class StocksController < ApplicationController
          skip_before_action :authenticate_user!, raise: false
          skip_before_action :verify_authenticity_token, raise: false


          # GET /api/v1/integrations/one_c/stocks
          def index
            # MVP: Just return stocks for the first warehouse or by param
            warehouse = Warehouse.first
            unless warehouse
              render json: { items: [], last_synced_at: nil }
              return
            end
            
            # Check if sync is needed (stale data > 1 hour)
            if warehouse.last_synced_at.nil? || warehouse.last_synced_at < 1.hour.ago
               # Avoid spamming jobs: could add a cache/redis lock here, but for MVP just fire it.
               # Ideally we should also check if a job is already running.
               SyncStocksJob.perform_later(warehouse.id)
               Rails.logger.info "Enqueued SyncStocksJob for warehouse #{warehouse.id} (Stale data)"
            end

            stocks = warehouse.warehouse_stocks.where("quantity > 0")
            
            # Map stocks to Product details
            items = []
            stocks.each do |stock|
              product = Product.find_by(sku: stock.product_sku)
              
              # Only show if product exists AND is active
              if product && product.is_active
                items << {
                  sku: stock.product_sku,
                  name: product.name,
                  price: product.price,
                  characteristics: product.characteristics,
                  quantity: stock.quantity,
                  synced_at: stock.synced_at
                }
              end
            end
            
            render json: {
              warehouse: warehouse.name,
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

                stock = warehouse.warehouse_stocks.find_or_initialize_by(product_sku: item[:nomenclature_code])
                stock.quantity = item[:quantity] || 0
                stock.synced_at = synced_now
                stock.save!
                
                # NOTE: Legacy Product.stock update disabled by user request to keep original catalog unchanged for now.
                # product = Product.find_by(sku: stock.product_sku)
                # if product
                #   total_quantity = WarehouseStock.where(product_sku: stock.product_sku).sum(:quantity)
                #   product.update_column(:stock, total_quantity)
                # end
                
                processed_count += 1
              end
            end

            render json: { status: 'success', processed_items: processed_count }
          rescue StandardError => e
            Rails.logger.error("1C Sync Error: #{e.message}")
            render json: { error: 'Internal Server Error during sync' }, status: :internal_server_error
          end
        end
      end
    end
  end
end
