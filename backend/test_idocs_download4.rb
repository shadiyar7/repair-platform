require_relative 'config/environment'
client = IDocs::Client.new
document_id = "806cd4fb-0439-49b3-4993-08de70ca8f6e"
response = client.instance_variable_get(:@conn).get("sync/external/documents-query/single/outbox/#{document_id}")
puts "HTTP: #{response.status}"
puts response.body
