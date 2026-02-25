require_relative 'config/environment'

user = User.find_by(email: 'client@repair.com') || User.last
if user
  user.update!(
    company_name: "ИП ШАДИЯР А Б",
    legal_address: "Жамбылский район, Аса, УЛИЦА ТЕМИР ЖОЛ, дом 6/1",
    actual_address: "Жамбылский район, Аса, УЛИЦА ТЕМИР ЖОЛ, дом 6/1",
    bin: "980107301250",
    inn: "980107301250",
    director_name: "Шадияр А.Б.",
    acting_on_basis: "Свидетельства ИП"
  )
  puts "Updated user profile to: #{user.company_name}"
  
  # Also sync all active requisites for this user
  user.company_requisites.where(is_active: true).each do |req|
    req.update!(
      company_name: user.company_name,
      legal_address: user.legal_address,
      actual_address: user.actual_address,
      bin: user.bin,
      inn: user.inn,
      director_name: user.director_name,
      acting_on_basis: user.acting_on_basis
    )
    puts "Synced requisite #{req.id}"
  end
end
