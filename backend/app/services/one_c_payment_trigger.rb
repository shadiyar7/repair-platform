class OneCPaymentTrigger
  # Hardcoded/Default Warehouse ID as per requirement if not available
  DEFAULT_WAREHOUSE_ID = "000000001"

  def initialize(order)
    @order = order
  end

  def call
    payload = build_payload
    result = send_to_debug_endpoint(payload)
    result
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
    url = "https://f577a0f8677a.ngrok-free.app/Integration/hs/int/post_payments"
    username = "администратор"
    password = "" 

    Rails.logger.info "1C Integration: Sending Order ##{order.id} to #{url}"
    
    result = { payload: payload, success: false, response_code: nil, response_body: nil }

    begin
      uri = URI(url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      
      request = Net::HTTP::Post.new(uri)
      request.basic_auth(username, password)
      request.content_type = 'application/json'
      request.body = payload.to_json

      response = http.request(request)

      Rails.logger.info "1C Response: #{response.code} - #{response.body}"
      
      result[:response_code] = response.code
      result[:response_body] = response.body

      if response.code.to_i >= 200 && response.code.to_i < 300
        result[:success] = true
        handle_success_response(response.body)
      else
        Rails.logger.error "1C Request Failed: #{response.code} #{response.body}"
      end
    rescue => e
      Rails.logger.error "1C Integration Error: #{e.message}"
      result[:error] = e.message
    end
    
    result
  end

  def handle_success_response(body)
    data = JSON.parse(body)
    # invoice_code is expected to be the Base64 PDF string
    invoice_code = data['image'] || data['base64'] || data['invoice_base64'] || data['file']

    if invoice_code.present?
      if order.update(invoice_base64: invoice_code)
        Rails.logger.info "Successfully saved 1C Invoice (Base64) to Order ##{order.id}"
      else
        Rails.logger.error "Failed to save 1C Invoice to Order ##{order.id}: #{order.errors.full_messages.join(', ')}"
      end
    else
      Rails.logger.warn "1C Response did not contain 'image', 'base64', 'invoice_base64', or 'file' key."
    end
  rescue JSON::ParserError => e
    Rails.logger.error "Failed to parse 1C response JSON: #{e.message}"
  end
end
