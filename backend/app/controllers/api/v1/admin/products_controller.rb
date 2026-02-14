module Api
  module V1
    module Admin
      class ProductsController < ApplicationController
        before_action :authenticate_user! # TODO: Admin check
        before_action :set_product, only: [:update, :destroy]

        # GET /api/v1/admin/products
        # Optional param: warehouse_id (to filter products available at that warehouse)
        def index
          if params[:warehouse_id].present?
            # Join with stocks if filtering by warehouse
            # Logic: Show products that have stocks in this warehouse OR just all products?
            # User said: "choose warehouse -> available goods".
            # So we find WarehouseStocks first, then find corresponding Products.
            
            stock_skus = WarehouseStock.where(warehouse_id: params[:warehouse_id]).pluck(:product_sku)
            @products = Product.where(sku: stock_skus)
          else
            @products = Product.all
          end
          
          render json: ProductSerializer.new(@products).serializable_hash
        end

        # GET /api/v1/admin/products/unlinked
        # Returns stocks that do NOT have a corresponding Product record (orphan 1C codes)
        def unlinked
          warehouse_id = params[:warehouse_id]
          
          # Find all entries in WarehouseStock
          scope = WarehouseStock.select(:nomenclature_code, :quantity, :synced_at, :warehouse_id)
          scope = scope.where(warehouse_id: warehouse_id) if warehouse_id.present?
          scope = scope.where.not(nomenclature_code: nil)

          # Find all existing Product nomenclature_codes
          existing_codes = Product.where.not(nomenclature_code: nil).pluck(:nomenclature_code)
          
          # Filter stocks where nomenclature_code is NOT in existing_codes
          unlinked_stocks = scope.where.not(nomenclature_code: existing_codes)
          
          render json: unlinked_stocks.map { |stock|
            {
              sku: stock.nomenclature_code, # Front expects "sku" key for the ID in the table? 
              nomenclature_code: stock.nomenclature_code,
              quantity: stock.quantity,
              synced_at: stock.synced_at,
              warehouse_id: stock.warehouse_id
            }
          }
        end

        # POST /api/v1/admin/products
        def create
          # Use specific params permitting to include nomenclature_code
          permitted = product_params
          
          @product = Product.new(permitted)
          
          if @product.save
            # If warehouse_id is passed, try to link/create stock
            if params[:warehouse_id].present?
              warehouse = Warehouse.find_by(id: params[:warehouse_id])
              if warehouse && @product.nomenclature_code.present?
                 # Try to find existing stock by nomenclature_code (from 1C sync) and link it?
                 # Or create new one?
                 stock = warehouse.warehouse_stocks.find_or_initialize_by(nomenclature_code: @product.nomenclature_code)
                 # Don't overwrite quantity if it exists, just ensure it exists
                 stock.synced_at ||= Time.now
                 stock.quantity ||= 0
                 stock.save!
              end
            end

            render json: ProductSerializer.new(@product).serializable_hash, status: :created
          else
            render json: { errors: @product.errors }, status: :unprocessable_entity
          end
        rescue => e
            Rails.logger.error "Product Create Error: #{e.message}"
            render json: { error: e.message }, status: :internal_server_error
        end # Added rescue block for 500 debugging

        # PATCH/PUT /api/v1/admin/products/:id
        def update
          if @product.update(product_params)
            render json: ProductSerializer.new(@product).serializable_hash
          else
            render json: { errors: @product.errors }, status: :unprocessable_entity
          end
        end

        # DELETE /api/v1/admin/products/:id
        def destroy
          @product.destroy
        end

        private

        def set_product
          @product = Product.find(params[:id])
        end

        def product_params
          # Map 1cId to nomenclature_code if passed
          p = params.require(:product).permit(
            :name, :sku, :price, :category, :is_active, 
            :description, :image_url, :warehouse_location,
            :nomenclature_code,
            characteristics: {} # Allow any JSON
          )
          
          # Compatibility: if frontend sends '1cId' or maps sku to nomenclature_code in a confusing way
          # User payload showed: product: {name: "...", sku: "00000000016", ...}
          # If the user put the 000016 in the "sku" field in the form, but meant it to be nomenclature_code...
          # We might need to swap them if sku looks like 1C code?
          # For now, let's assume the frontend will be updated or user enters data correctly.
          # BUT, for the "New Arrivals" feature, the frontend sends the "sku" (which IS the nomenclature code from the unlinked list) as "sku" param.
          
          # If creating from "New Arrivals", we might want to prioritize using that value as nomenclature_code
          if p[:sku] && p[:sku].match?(/^\d+$/) && p[:nomenclature_code].blank?
             # Auto-detect: if SKU looks like 1C ID (digits) and nomenclature_code is blank, treat as nomenclature_code?
             # User said: "edit ... sku". So they probably want to assign a REAL SKU (WS-...) and keep 000016 as nomenclature_code.
             # So we should trust the params.
          end

          p
        end
      end
    end
  end
end
