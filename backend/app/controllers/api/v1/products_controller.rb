class Api::V1::ProductsController < ApplicationController
  skip_before_action :authenticate_user!
  def index
    check_sync_status

    products = Product.all
    render json: ProductSerializer.new(products).serializable_hash
  end

  private

  def check_sync_status
    # MVP: Check sync status for the first warehouse
    warehouse = Warehouse.first
    return unless warehouse

    last_sync = warehouse.warehouse_stocks.maximum(:synced_at)

    # Trigger sync if never synced OR synced more than 15 minutes ago
    if last_sync.nil? || last_sync < 15.minutes.ago
      SyncStocksJob.perform_later(warehouse.id)
    end
  end

  def show
    product = Product.find(params[:id])
    render json: ProductSerializer.new(product).serializable_hash
  end
end
