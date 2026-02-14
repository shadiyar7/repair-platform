class OrderSerializer
  include JSONAPI::Serializer
  attributes :status, :total_amount, :city, :delivery_address, :delivery_notes, :created_at, :order_items,
             :driver_name, :driver_phone, :driver_car_number, :driver_arrival_time, :driver_comment,
             :director_signed_at, :smart_link_token, :invoice_base64

  attribute :payment_receipt_url do |object|
    if object.payment_receipt.attached?
      Rails.application.routes.url_helpers.rails_blob_url(object.payment_receipt, host: 'repair-platform.onrender.com') # Or dynamic host
    else
      nil
    end
  end

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
