require_relative 'config/environment'
order = Order.where.not(idocs_document_id: nil).where(idocs_status: 'sent_to_client').last
if order
  puts "Latest Order ID: #{order.id}, Doc ID: #{order.idocs_document_id}"
  client = IDocs::Client.new
  response = client.instance_variable_get(:@conn).get("sync/single/document/GetDocumentPrintFormByDocumentId/#{order.idocs_document_id}")
  puts "HTTP: #{response.status}"
  if response.success?
    puts "Downloaded #{response.body.bytesize} bytes"
    File.binwrite("test_print_form_#{order.id}.pdf", response.body)
  else
    puts response.body
  end
else
  puts "No orders found with sent_to_client"
end
