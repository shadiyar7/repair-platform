require_relative 'config/environment'

reqs = CompanyRequisite.all
reqs.each do |req|
  puts "Found ID: #{req.id}, Name: #{req.company_name}, User ID: #{req.user_id}"
  # Just delete it if it's "Test Client LLP (Main)"
  if req.company_name.to_s.include?("Test Client")
     puts "Deleting!"
     req.destroy
  end
end
