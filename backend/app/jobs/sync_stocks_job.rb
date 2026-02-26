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
    uri = URI(one_c_url)
    
    warehouse_id_1c = warehouse.external_id_1c.to_s.rjust(9, "0")
    Rails.logger.info "🛰 [SyncStocksJob] Triggering 1C Pull from: #{one_c_url} with body ID: #{warehouse_id_1c}"
    
    https = Net::HTTP.new(uri.host, uri.port)
    https.use_ssl = true
    
    request = Net::HTTP::Get.new(uri)
    request["Content-Type"] = "application/json"
    
    # Authenticate: username="integration", password="Aa123456!!"
    request.basic_auth("integration", "Aa123456!!")
    
    # Body: {"warehouse_id_1c": "..."}
    # warehouse_id_1c is dynamic based on the warehouse being synced
    request.body = JSON.dump({
      "warehouse_id_1c": warehouse_id_1c
    })


    
    begin
      response = https.request(request)
      Rails.logger.info "⚡️ [1C Sync] Triggered for Warehouse #{warehouse.name} (#{warehouse_id_1c}). Response: #{response.code} #{response.message}"
      # Rails.logger.debug "⚡️ [1C Sync] Response Body: #{response.body}"
    rescue StandardError => e
      Rails.logger.error "⚠️ [1C Sync] Failed to trigger sync: #{e.message}"
    end
  end
end
