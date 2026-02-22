require_relative 'config/environment'

client = IDocs::Client.new
document_id = "806cd4fb-0439-49b3-4993-08de70ca8f6e"

response = client.instance_variable_get(:@conn).get("sync/single/document/GetDocumentPrintFormByDocumentId/#{document_id}")

if response.success?
  puts "Success! Downloaded #{response.body.bytesize} bytes"
else
  puts "Error: #{response.status} - #{response.body}"
end
