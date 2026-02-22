require 'base64'
require 'tempfile'
require_relative 'config/environment'

document_id = "a668e123-e7a7-46ed-499b-08de70ca8f6e"
employee_id = "08e9f2df-1b6d-447d-3db0-08de6cc71a03"
idempotency_ticket = "1070e54d-7d5a-4ce8-9697-a3987913b1a6"

puts "Uploading real detached CMS signature..."
signature_data = File.read("test_signature.cms.b64").strip

temp_file = Tempfile.new(['signature', '.cms'])
temp_file.binmode
temp_file.write(Base64.decode64(signature_data))
temp_file.rewind

payload = {
  signatureContent: Faraday::UploadIO.new(temp_file.path, 'application/octet-stream')
}

upload_conn = Faraday.new(url: IDocs::Client::BASE_URL) do |faraday|
  faraday.request :multipart
  faraday.request :url_encoded
  faraday.adapter Faraday.default_adapter
  faraday.headers['Authorization'] = "Bearer #{IDocs::Client::TOKEN}"
  faraday.headers['Accept'] = 'application/json'
end

response = upload_conn.post('sync/blobs/document-signature-content', payload)

temp_file.close
temp_file.unlink

blob_id = JSON.parse(response.body).dig("response", "blobId")
puts "Upload response: #{response.status} #{response.body}"
puts "Blob ID: #{blob_id}"

if blob_id
  puts "\nSaving signature..."
  client = IDocs::Client.new
  result = client.save_signature(document_id, employee_id, blob_id, idempotency_ticket)
  puts "Save response: #{result.inspect}"
end
