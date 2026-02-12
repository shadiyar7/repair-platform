class OrderSerializer
  include JSONAPI::Serializer
  attributes :status, :total_amount, :delivery_address, :delivery_notes, :created_at, :order_items,
             :driver_name, :driver_phone, :driver_car_number, :driver_arrival_time, 
             :director_signed_at, :smart_link_token, :invoice_base64

  attribute :order_items do |object|
    object.order_items.map do |item|
      {
        id: item.id,
        product_id: item.product_id,
        product_name: item.product&.name,
        quantity: item.quantity,
        price: item.price || item.product&.price
      }
    end
  end
end
