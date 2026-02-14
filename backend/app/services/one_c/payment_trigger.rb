module OneC
  class PaymentTrigger
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
      # For now, we prefer to call the controller method internally or just log it 
      # since calling HTTP locally might be brittle without full URL.
      # User asked to "create a new endpoint let it send there".
      # But since we are inside the app, we can just instantiate the controller or log.
      # However, to strictly follow "send request", we can use Net::HTTP to localhost if needed,
      # OR just log it here effectively acting as the endpoint logic.
      
      # But user specifically said "create a new endpoint".
      # So let's try to simulate the call or actually verify the data structure via logging here first
      # as the user said "I will look in logs".
      
      Rails.logger.info "---------------------------------------------------"
      Rails.logger.info "1C INTEGRATION DEBUG TRIGGER"
      Rails.logger.info "Payload for Order ##{order.id}:"
      Rails.logger.info JSON.pretty_generate(payload)
      Rails.logger.info "---------------------------------------------------"
      
      # If we want to really hit the endpoint:
      # uri = URI("http://localhost:3000/api/v1/integrations/one_c/debug_trigger")
      # ...
      # But usually logging from Service is enough for "verify in logs".
      # The user said "create a new endpoint... send there... but for now send to internal method".
      # "INTERNAL METHOD" suggests just calling a method.
      
      return payload
    end
  end
end
