class SyncStocksJob < ApplicationJob
  queue_as :default

  def perform(warehouse_id)
    warehouse = Warehouse.find_by(id: warehouse_id)
    return unless warehouse
    
    # Check if we have a configured 1C URL (Environment Variable)
    one_c_url = ENV['ONE_C_API_URL'] 
    
    if one_c_url.present?
      # TODO: Implement actual HTTP request when 1C is ready
      # Client.post(one_c_url, json: { 
      #   warehouse_id_1c: warehouse.external_id_1c,
      #   callback_url: "https://repair-platform.onrender.com/api/v1/integrations/one_c/stocks"
      # })
      Rails.logger.info "⚡️ [Job] Triggered 1C Sync for Warehouse #{warehouse.name} -> #{one_c_url}"
    else
      Rails.logger.warn "⚠️ [Job] 1C Sync skipped: ONE_C_API_URL not set. Warehouse: #{warehouse.name}"
    end
  end
end
