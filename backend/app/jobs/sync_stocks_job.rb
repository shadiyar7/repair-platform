class SyncStocksJob < ApplicationJob
  queue_as :default

  def perform(warehouse_id)
    warehouse = Warehouse.find_by(id: warehouse_id)
    return unless warehouse
    
    # 1C Endpoint Configuration
    # We use ENV variable to distinguish between Local (Ngrok) and Production (Real 1C)
    # Default to the ngrok URL provided for testing if ENV is missing
    # Use production URL as fallback if ENV is missing
    production_url = "https://1cstart.itsheff.cloud/komandeersykixo/hs/int/get_stocks"
    one_c_url = ENV.fetch('ONE_C_API_URL', production_url)
    
    # 1C Expects a GET request. For GET, it's better to pass warehouse_id in query params.
    warehouse_id_1c = warehouse.external_id_1c.to_s.rjust(9, "0")
    uri = URI(one_c_url)
    params = { warehouse_id_1c: warehouse_id_1c }
    uri.query = URI.encode_www_form(params)
    
    Rails.logger.info "🛰 [SyncStocksJob] Triggering 1C Pull from: #{uri}"
    
    https = Net::HTTP.new(uri.host, uri.port)
    https.use_ssl = true
    
    request = Net::HTTP::Get.new(uri)
    request["Content-Type"] = "application/json"
    
    # Authenticate: username="администратор", password=""
    request.basic_auth("администратор", "")

    
    begin
      response = https.request(request)
      Rails.logger.info "⚡️ [1C Sync] Triggered for Warehouse #{warehouse.name} (#{warehouse_id_1c}). Response: #{response.code} #{response.message}"
      # Rails.logger.debug "⚡️ [1C Sync] Response Body: #{response.body}"
    rescue StandardError => e
      Rails.logger.error "⚠️ [1C Sync] Failed to trigger sync: #{e.message}"
    end
  end
end
