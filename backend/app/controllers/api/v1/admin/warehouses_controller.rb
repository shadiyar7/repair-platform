module Api
  module V1
    module Admin
      class WarehousesController < ApplicationController
        before_action :authenticate_user! # TODO: Add admin role check
        before_action :set_warehouse, only: [:show, :update, :destroy]

        # GET /api/v1/admin/warehouses
        def index
          warehouses = Warehouse.all.order(:id)
          render json: warehouses
        end

        # GET /api/v1/admin/warehouses/:id
        def show
          render json: @warehouse
        end

        # POST /api/v1/admin/warehouses
        def create
          @warehouse = Warehouse.new(warehouse_params)

          if @warehouse.save
            render json: @warehouse, status: :created
          else
            render json: { errors: @warehouse.errors }, status: :unprocessable_entity
          end
        end

        # PATCH/PUT /api/v1/admin/warehouses/:id
        def update
          if @warehouse.update(warehouse_params)
            render json: @warehouse
          else
            render json: { errors: @warehouse.errors }, status: :unprocessable_entity
          end
        end

        # DELETE /api/v1/admin/warehouses/:id
        def destroy
          @warehouse.destroy
        end

        private

        def set_warehouse
          @warehouse = Warehouse.find(params[:id])
        end

        def warehouse_params
          params.require(:warehouse).permit(:name, :external_id_1c, :address)
        end
      end
    end
  end
end
