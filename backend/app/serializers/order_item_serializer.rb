class OrderItemSerializer
  include JSONAPI::Serializer
  attributes :quantity, :price
  belongs_to :product
end
