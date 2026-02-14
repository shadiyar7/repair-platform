class ProductSerializer
  include JSONAPI::Serializer
  attributes :name, :sku, :nomenclature_code, :price, :category, :is_active, :stock, :description, :image_url, :warehouse_location, :characteristics
end
