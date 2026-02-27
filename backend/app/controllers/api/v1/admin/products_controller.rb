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
            stocks = WarehouseStock.where(warehouse_id: params[:warehouse_id])
            stock_skus = stocks.pluck(:product_sku).compact
            stock_codes = stocks.pluck(:nomenclature_code).compact
            
            @products = Product.where(is_deleted: false).where(
              "sku IN (:skus) OR nomenclature_code IN (:codes)", skus: stock_skus, codes: stock_codes
            )
            
            serialized = ProductSerializer.new(@products).serializable_hash
            serialized[:data].each do |p_node|
              sku = p_node.dig(:attributes, :sku)
              code = p_node.dig(:attributes, :nomenclature_code)
              
              stock = stocks.find { |s| (s.product_sku.present? && s.product_sku == sku) || (s.nomenclature_code.present? && s.nomenclature_code == code) }
              p_node[:attributes][:quantity] = stock&.quantity || 0
            end
            return render json: serialized
          else
            @products = Product.where(is_deleted: false)
          end
          
          render json: ProductSerializer.new(@products).serializable_hash
        end

        # GET /api/v1/admin/products/unlinked
        # Returns stocks that do NOT have a corresponding Product record (orphan 1C codes)
        def unlinked
          warehouse_id = params[:warehouse_id]
          
          # Find all entries in WarehouseStock
          scope = WarehouseStock.select(:nomenclature_code, :product_sku, :quantity, :synced_at, :warehouse_id, :nomenclature_name)
          scope = scope.where(warehouse_id: warehouse_id) if warehouse_id.present?

          existing_codes = Product.where.not(nomenclature_code: nil).pluck(:nomenclature_code)
          existing_skus = Product.where.not(sku: nil).pluck(:sku)
          
          unlinked_stocks = scope.to_a.reject do |stock|
            (stock.nomenclature_code.present? && existing_codes.include?(stock.nomenclature_code)) ||
            (stock.product_sku.present? && existing_skus.include?(stock.product_sku))
          end
          unlinked_stocks.select! { |s| s.nomenclature_code.present? || s.product_sku.present? }
          
          render json: unlinked_stocks.map { |stock|
            {
              sku: stock.nomenclature_code || stock.product_sku, # Fallback
              nomenclature_code: stock.nomenclature_code || stock.product_sku,
              nomenclature_name: stock.nomenclature_name, # Added for frontend suggestion
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
                stock.nomenclature_name = @product.name # Sync name from product form
                stock.save!
              end
            end

            # Always sync nomenclature_name for ALL stocks with this code across all warehouses
            if @product.nomenclature_code.present?
              WarehouseStock.where(nomenclature_code: @product.nomenclature_code).update_all(nomenclature_name: @product.name)
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
          if @product.order_items.exists?
            @product.update(is_deleted: true)
            render json: { message: "Product hidden (is_deleted: true) because it has existing orders." }, status: :ok
          else
            @product.destroy
            head :no_content
          end
        rescue => e
            render json: { error: e.message }, status: :unprocessable_entity
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
            characteristics: {}, # Allow any JSON
            uids: [] # Allow array of strings
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
