require_relative 'config/environment'
client = IDocs::Client.new
conn = Faraday.new(url: IDocs::Client::BASE_URL) do |f|
  f.adapter Faraday.default_adapter
  f.headers['Authorization'] = "Bearer #{IDocs::Client::TOKEN}"
  f.headers['Content-Type'] = 'application/json'
end
resp = conn.post("sync/external/outbox/signature/quick-sign/save") do |req|
  req.body = { documentId: "1234" }.to_json
end
puts "Status: #{resp.status}"
puts resp.body
