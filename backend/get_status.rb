require_relative 'config/environment'
client = IDocs::Client.new
conn = Faraday.new(url: IDocs::Client::BASE_URL) do |faraday|
  faraday.adapter Faraday.default_adapter
  faraday.headers['Authorization'] = "Bearer #{IDocs::Client::TOKEN}"
  faraday.headers['Content-Type'] = 'application/json'
end
resp = conn.get("sync/single/document/GetDocumentStatusByDocumentId/448cf900-0b38-483c-49a0-08de70ca8f6e")
puts "Status: #{resp.status}"
puts resp.body
