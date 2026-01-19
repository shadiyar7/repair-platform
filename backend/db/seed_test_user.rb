user = User.find_or_initialize_by(email: 'test_client_final@repair.com')
user.password = 'password123'
user.role = 'client'
user.company_name = 'Test Logistics LLP'
user.director_name = 'John Doe'
user.acting_on_basis = 'Charter'
user.legal_address = 'Almaty, Satpayev 1'
user.actual_address = 'Almaty, Satpayev 1'
user.bin = '123456789012'
user.iban = 'KZ123456789012345678'
user.swift = 'TESTKZZX'
user.phone = '+77771112233'
user.save!
puts "Test user created successfully!"
