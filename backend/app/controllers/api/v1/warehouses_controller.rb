module Api
  module V1
    class WarehousesController < ApplicationController
      # GET /api/v1/warehouses
      def index
        warehouses = Warehouse.all.order(:external_id_1c)
        render json: WarehouseSerializer.new(warehouses).serializable_hash.to_json
      end

      # GET /api/v1/warehouses/:id
      def show
        warehouse = Warehouse.find(params[:id])
        render json: WarehouseSerializer.new(warehouse).serializable_hash.to_json
      end
    end
  end
end
