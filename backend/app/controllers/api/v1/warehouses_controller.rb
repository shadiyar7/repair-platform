module Api
  module V1
    class WarehousesController < ApplicationController
      # GET /api/v1/warehouses
      def index
        warehouses = Warehouse.all.order(:external_id_1c)
        render json: warehouses
      end

      # GET /api/v1/warehouses/:id
      def show
        warehouse = Warehouse.find(params[:id])
        render json: warehouse
      end
    end
  end
end
