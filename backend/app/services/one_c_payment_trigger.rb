class OneCPaymentTrigger
  # Hardcoded/Default Warehouse ID as per requirement if not available
  DEFAULT_WAREHOUSE_ID = "000000001"

  def initialize(order)
    @order = order
  end

  def call
    payload = build_payload
    send_to_debug_endpoint(payload)
  end

  private

  attr_reader :order

  def build_payload
    requisites = order.company_requisite
    
    {
      "binn" => requisites&.bin || "NO_BIN",
      "ID" => order.id,
      "companyName" => requisites&.company_name || "NO_COMPANY",
      "warehouseId" => DEFAULT_WAREHOUSE_ID, # Or fetch from elsewhere if logic changes
      "totalPrice" => order.total_amount.to_f,
      "items" => build_items
    }
  end

  def build_items
    order.order_items.map do |item|
      {
        "nomenclature_code" => item.product&.sku || "NO_SKU",
        "quantity" => item.quantity,
        "price" => item.price.to_f
      }
    end
  end

  def send_to_debug_endpoint(payload)
    Rails.logger.info "---------------------------------------------------"
    Rails.logger.info "1C INTEGRATION DEBUG TRIGGER"
    Rails.logger.info "Payload for Order ##{order.id}:"
    Rails.logger.info JSON.pretty_generate(payload)
    Rails.logger.info "---------------------------------------------------"
    
    return payload
  end
end
