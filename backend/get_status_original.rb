require_relative 'config/environment'
client = IDocs::Client.new
conn = Faraday.new(url: IDocs::Client::BASE_URL) do |f|
  f.adapter Faraday.default_adapter
  f.headers['Authorization'] = "Bearer #{IDocs::Client::TOKEN}"
end
puts conn.get("sync/single/document/GetDocumentStatusByDocumentId/806cd4fb-0439-49b3-4993-08de70ca8f6e").body
