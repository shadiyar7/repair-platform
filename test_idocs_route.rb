require_relative 'backend/config/environment'

client = IDocs::Client.new

# Generate dummy file
file_path = Rails.root.join('public', 'robots.txt')
if !File.exist?(file_path)
  File.write(file_path, "test")
end

upload_res = client.upload_file(file_path.to_s)
blob_id = upload_res['blobId']

metadata = {
  name: "Test Document #{Time.current.to_i}",
  number: "TEST-#{Time.current.to_i}",
  date: Time.current.to_i,
  group: "Договоры",
  author_id: "08e9f2df-1b6d-447d-3db0-08de6cc71a03"
}

doc_res = client.create_document(metadata, blob_id)
new_doc_id = doc_res['documentId']
puts "Created doc: #{new_doc_id}"

conn = Faraday.new(url: IDocs::Client::BASE_URL) do |f|
  f.headers['Authorization'] = "Bearer #{IDocs::Client::TOKEN}"
  f.headers['Content-Type'] = 'application/json'
end

def test_route(conn, new_doc_id, is_sender_payer, is_payer)
  payload = {
    documentId: new_doc_id,
    employeeId: "08e9f2df-1b6d-447d-3db0-08de6cc71a03",
    route: {
        external: {
            isSignRequiredBySender: true,
            nodes: [
                {
                    order: 0,
                    counterpartyBin: "123456789012",
                    comment: "Test",
                    isIndividual: false,
                    counterpartyEmails: ["test@example.com"],
                    isSignRequiredByCounterparty: true
                }
            ]
        }
    }
  }
  
  if !is_sender_payer.nil?
    payload[:route][:external][:isSenderPayer] = is_sender_payer
  end
  
  if !is_payer.nil?
    payload[:route][:external][:nodes][0][:isPayer] = is_payer
  end

  res = conn.post('sync/external/outbox/route/quick-route/create', payload.to_json)
  puts "isSenderPayer: #{is_sender_payer.inspect}, isPayer: #{is_payer.inspect} => Status: #{res.status} Body: #{res.body}"
end

puts "Testing different payment combinations..."
test_route(conn, new_doc_id, true, false)
test_route(conn, new_doc_id, nil, true)
test_route(conn, new_doc_id, true, nil)
test_route(conn, new_doc_id, nil, nil)
