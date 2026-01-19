class ProductSerializer
  include JSONAPI::Serializer
  attributes :name, :sku, :price, :category, :stock, :description, :image_url, :warehouse_location, :characteristics
end
