class SyncStocksJob < ApplicationJob
  queue_as :default

  def perform(warehouse_id)
    warehouse = Warehouse.find_by(id: warehouse_id)
    return unless warehouse
    
    # 1C Endpoint Configuration
    # We use ENV variable to distinguish between Local (Ngrok) and Production (Real 1C)
    # Default to the ngrok URL provided for testing if ENV is missing
    one_c_url = ENV.fetch('ONE_C_API_URL', "https://f577a0f8677a.ngrok-free.app/Integration/hs/int/get_stocks")
    url = URI(one_c_url)
    
    https = Net::HTTP.new(url.host, url.port)
    https.use_ssl = true
    
    request = Net::HTTP::Get.new(url)
    request["Content-Type"] = "application/json"
    
    # Authenticate: username="администратор", password=""
    request.basic_auth("администратор", "")
    
    # Body: {"warehouse_id_1c": "..."}
    # Using the warehouse's external ID or the hardcoded "000000001" if requested for test?
    # User example: "000000001". Let's use the warehouse's stored external_id_1c.
    request.body = JSON.dump({
      "warehouse_id_1c": warehouse.external_id_1c || "000000001"
    })
    
    begin
      response = https.request(request)
      Rails.logger.info "⚡️ [1C Sync] Triggered for Warehouse #{warehouse.name}. Response: #{response.code} #{response.message}"
    rescue StandardError => e
      Rails.logger.error "⚠️ [1C Sync] Failed to trigger sync: #{e.message}"
    end
  end
end
