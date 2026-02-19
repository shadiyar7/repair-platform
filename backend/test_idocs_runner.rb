
require 'prawn'

begin
  puts "Initializing IDocs::Client..."
  client = IDocs::Client.new
  puts "Client initialized."

  puts "POST references/company-employees with pagination..."
  
  # PaginatedQueryVM structure based on common .NET patterns used in iDocs
  payload = {
    pageIndex: 1,
    pageSize: 100,
    isArchive: false
  }

  res = client.instance_variable_get(:@conn).post('sync/references/company-employees') do |req|
    req.headers['Content-Type'] = 'application/json'
    req.body = payload.to_json
  end
  
  puts "Status: #{res.status}"
  if res.success?
    puts "Body: #{res.body}"
  else
    puts "Error Body: #{res.body}"
  end

rescue => e
  puts "An error occurred: #{e.message}"
end
