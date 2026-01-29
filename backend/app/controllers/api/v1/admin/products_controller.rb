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

        # POST /api/v1/admin/products
        def create
          @product = Product.new(product_params)
          
          if @product.save
            # If warehouse_id is passed (e.g., from admin UI context), create initial stock entry
            if params[:warehouse_id].present?
              warehouse = Warehouse.find_by(id: params[:warehouse_id])
              if warehouse
                WarehouseStock.create!(
                  warehouse: warehouse,
                  product_sku: @product.sku,
                  quantity: 0, # Initial stock 0, manager updates it
                  synced_at: Time.now
                )
              end
            end

            render json: ProductSerializer.new(@product).serializable_hash, status: :created
          else
            render json: { errors: @product.errors }, status: :unprocessable_entity
          end
        end

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
          # Map 1cId to sku if passed in specific JSON format, otherwise strict permit
          # The simplified user requirement keys: Name, Characteristics, Type, Price, isActive, 1cId
          
          # If frontend sends "1cId", we should map it to "sku".
          # But better to just standardise on frontend sending "sku".
          
          params.require(:product).permit(
            :name, :sku, :price, :category, :is_active, 
            :description, :image_url, :warehouse_location, # Legacy fields
            characteristics: {} # Allow any JSON
          )
        end
      end
    end
  end
end
