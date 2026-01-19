# verification_script.rb
require_relative 'config/environment'

puts "== Starting Verification =="

# 1. Create User
user = User.find_or_create_by!(email: 'test_driver@example.com') do |u|
  u.role = 'driver'
  u.password = 'password123'
  u.jti = SecureRandom.uuid
end
puts "[OK] User created/found: #{user.email}"

# 2. Create Order
order = Order.create!(
  user: user,
  delivery_address: 'Test Address',
  delivery_notes: 'Test Notes',
  status: 'searching_driver'
)

# 3. Verify Token Generation
if order.smart_link_token.present?
  puts "[OK] SmartLink Token Generated: #{order.smart_link_token}"
else
  puts "[FAIL] SmartLink Token is missing!"
  exit 1
end

# 4. Verify Della Mock Service
puts "Testing Della Mock Service..."
service = Logistics::DellaMockService.new(order)
result = service.call
puts "[OK] Della Mock Result: #{result.inspect}"

puts "== Verification Complete =="
