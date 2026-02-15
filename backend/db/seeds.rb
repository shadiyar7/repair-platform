# Idempotent Seeds

puts "Seeding database..."

# 1. Users
# Admin
User.find_or_create_by!(email: 'admin@repair.com') do |u|
  u.password = 'password123'
  u.role = 'admin'
  u.company_name = 'DYNAMIX HQ'
  u.phone = '+77010000000'
end

# Warehouse Manager
User.find_or_create_by!(email: 'warehouse@repair.com') do |u|
  u.password = 'password123'
  u.role = 'warehouse'
  u.company_name = 'Central Warehouse'
  u.phone = '+77020000000'
end

# Client
client = User.find_or_create_by!(email: 'client@repair.com') do |u|
  u.password = 'password123'
  u.role = 'client'
  u.company_name = 'Test Client LLP'
  u.phone = '+77050000000'
end

# Driver
User.find_or_create_by!(email: 'driver@repair.com') do |u|
  u.password = 'password123'
  u.role = 'driver'
  u.company_name = 'Logistics Trans'
  u.phone = '+77070000000'
end

# 2. Company Requisites
CompanyRequisite.find_or_create_by!(user: client) do |cr|
  cr.company_name = 'Test Client LLP (Main)'
  cr.bin = '123456789012'
  cr.legal_address = 'Almaty, Dostyk 1'
  cr.actual_address = 'Almaty, Dostyk 1'
  cr.bank_name = 'Halyk Bank'
  cr.iban = 'KZ0000000'
  cr.swift = 'HALYK'
end

# 3. Warehouses (1C Simulation)
puts "Seeding Warehouses..."
# IDs from User Screenshot:
# 000000001 - Основной склад (Павлодар)
# 000000003 - Склад Атырау
# 000000005 - Склад Аягоз
# 000000004 - Склад Караганда
# 000000002 - Склад Шымкент

warehouses_data = [
  { name: 'Павлодар (Основной)', id_1c: '000000001' },
  { name: 'Атырау', id_1c: '000000003' },
  { name: 'Аягоз', id_1c: '000000005' },
  { name: 'Караганда', id_1c: '000000004' },
  { name: 'Шымкент', id_1c: '000000002' }
]

warehouses = []

warehouses_data.each do |data|
  # Use string for external_id_1c to match 1C format exactly
  wh = Warehouse.find_or_create_by!(external_id_1c: data[:id_1c]) do |w|
    w.name = data[:name]
    w.address = "#{data[:name]}, Промзона"
    w.last_synced_at = Time.now - 2.hours # Set as stale to test sync trigger
  end
  # Ensure name is updated if it exists
  wh.update!(name: data[:name])
  warehouses << wh
end
# Create Default Admin
admin_email = 'admin@dynamix.kz'
unless User.exists?(email: admin_email)
  User.create!(
    email: admin_email,
    password: '@Astana2026',
    password_confirmation: '@Astana2026',
    role: 'admin',
    job_title: 'System Administrator',
    email_confirmed: true,
    phone: '+77770000000'
  )
  puts "Created Default Admin: #{admin_email}"
else
  puts "Admin already exists: #{admin_email}"
end
# 4. Products & Stocks
puts "Seeding Products & Stocks..."

# Wheelsets
thickness_ranges = ['30-34', '35-39', '40-44', '45-49', '50-54', '55-59', '60-64', '64-69', 'СОНК']
thickness_ranges.each do |range|
  warehouses.each do |wh|
    sku = "WS-#{range.gsub('-', '')}-#{wh.external_id_1c}"
    
    product = Product.find_or_create_by!(sku: sku) do |p|
      p.name = "Колесная пара (толщина #{range} мм)"
      p.price = 180000 + (range.to_i * 1000)
      p.category = 'Колесные пары'
      p.stock = 0 # Stock is tracked in WarehouseStock
      p.characteristics = { thickness: range }
      p.is_active = true
      p.warehouse_location = wh.name # Legacy field, can be kept for simple display
    end

    # Create/Update Stock
    stock_qty = rand(3..20)
    WarehouseStock.find_or_create_by!(warehouse: wh, product_sku: sku) do |ws|
      ws.quantity = stock_qty
      ws.synced_at = Time.now
    end
  end
end

# Casting
casting_types = ['Боковая рама', 'Надрессорная балка']
age_ranges = ['1-5 лет', '6-10 лет', '11-15 лет', '16-20 лет', '21-25 лет']

casting_types.each do |type|
  age_ranges.each do |age|
    warehouses.each do |wh|
      sku = "CST-#{type[0..2].upcase}-#{age.gsub(' ', '')}-#{wh.external_id_1c}"
      
      product = Product.find_or_create_by!(sku: sku) do |p|
        p.name = "#{type} (#{age})"
        p.price = 90000.00 - (age.to_i * 1000)
        p.category = 'Литье'
        p.stock = 0
        p.characteristics = { age: age }
        p.is_active = true
        p.warehouse_location = wh.name
      end

       # Create/Update Stock
      stock_qty = rand(5..15)
      WarehouseStock.find_or_create_by!(warehouse: wh, product_sku: sku) do |ws|
        ws.quantity = stock_qty
        ws.synced_at = Time.now
      end
    end
  end
end

puts "Database seeded successfully!"
