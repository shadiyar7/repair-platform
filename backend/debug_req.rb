require_relative 'config/environment'

user = User.find_by(email: 'shadiyar7@gmail.com') || User.last
puts "User: #{user.email}, company_name: #{user.company_name}"

reqs = user.company_requisites
puts "Requisites:"
reqs.each do |req|
  puts " - ID: #{req.id}, Name: '#{req.company_name}', Bank: '#{req.bank_name}', IBAN: '#{req.iban}'"
end
