require_relative 'config/environment'

user = User.find_by(email: 'client@repair.com') || User.find_by(email: 'shadiyar7@gmail.com') || User.last
puts "Looking at User: #{user.email}"
reqs = CompanyRequisite.where(user_id: user.id)
reqs.each do |req|
  puts "ID: #{req.id}, Name: #{req.company_name}, Bank: #{req.bank_name}"
end

