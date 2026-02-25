require_relative 'config/environment'

req = CompanyRequisite.find_by(id: 1)
if req
    puts "Deleting Requisite: #{req.company_name}"
    req.destroy
else
    puts "Requisite 1 not found"
end

# Let's also find ANY requisite with "Test Client LLP"
reqs = CompanyRequisite.where("company_name LIKE ?", "%Test Client%")
reqs.each do |r|
    puts "Found and deleting: #{r.company_name} (ID: #{r.id})"
    r.destroy
end
