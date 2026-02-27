class ProductSerializer
  include JSONAPI::Serializer
  attributes :name, :sku, :nomenclature_code, :price, :category, :is_active, 
             :description, :image_url, :characteristics, :uids

  attribute :warehouse_stocks_map do |object|
    # Returns { "WarehouseName" => quantity }
    object.warehouse_stocks.includes(:warehouse).each_with_object({}) do |stock, map|
      map[stock.warehouse.name] = stock.quantity.to_f
    end
  end

  attribute :stock do |object|
    # Return total sum across all warehouses for the catalog "total" view
    object.warehouse_stocks.sum(:quantity).to_f
  end
end
