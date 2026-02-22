require_relative 'config/environment'
client = IDocs::Client.new
conn = Faraday.new(url: IDocs::Client::BASE_URL) do |f|
  f.adapter Faraday.default_adapter
  f.headers['Authorization'] = "Bearer #{IDocs::Client::TOKEN}"
end
puts conn.get("sync/references/company-employees/permission/08e9f2df-1b6d-447d-3db0-08de6cc71a03").body
