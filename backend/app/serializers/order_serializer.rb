class OrderSerializer
  include JSONAPI::Serializer
  attributes :id, :status, :total_amount, :city, :delivery_address, :delivery_notes, :created_at, :order_items,
             :driver_name, :driver_phone, :driver_car_number, :driver_arrival_time, :driver_comment, :delivery_price,
             :director_signed_at, :smart_link_token, :invoice_base64, :is_verified, :origin_city

  attribute :origin_city do |object|
    # Assuming all items in an order come from the same warehouse for now, or just taking the first one.
    # In a real multi-warehouse scenario, this might need to be a list or primary warehouse.
    object.order_items.first&.product&.warehouse_location || 'Основной склад'
  end

  attribute :payment_receipt_url do |object|
    if object.payment_receipt.attached?
      Rails.application.routes.url_helpers.rails_blob_url(object.payment_receipt, host: 'repair-platform.onrender.com') # Or dynamic host
    else
      nil
    end
  end

  attribute :company_requisite do |object|
    if object.company_requisite
      {
        id: object.company_requisite.id,
        company_name: object.company_requisite.company_name,
        bin: object.company_requisite.bin
      }
    else
      nil
    end
  end

  attribute :contract_url do |object|
    if object.document.attached?
      Rails.application.routes.url_helpers.rails_blob_url(object.document, host: 'repair-platform.onrender.com')
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
        price: item.price || item.product&.price,
        sku: item.product&.sku,
        warehouse: item.product&.warehouse_location # Assuming simple string for now, or fetch warehouse object if needed
      }
    end
  end
end
