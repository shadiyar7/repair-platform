# Clear existing data
puts "Cleaning database..."
OrderItem.delete_all
SmartLinkToken.delete_all if defined?(SmartLinkToken)
Order.delete_all
Product.delete_all
CompanyRequisite.delete_all
User.delete_all

puts "Creating Users..."

# Admin
User.create!(
  email: 'admin@repair.com',
  password: 'password123',
  role: 'admin',
  company_name: 'DYNAMIX HQ',
  phone: '+77010000000'
)

# Warehouse Manager
User.create!(
  email: 'warehouse@repair.com',
  password: 'password123',
  role: 'warehouse',
  company_name: 'Central Warehouse',
  phone: '+77020000000'
)

# Client
client = User.create!(
  email: 'client@repair.com',
  password: 'password123',
  role: 'client',
  company_name: 'Test Client LLP',
  phone: '+77050000000'
)

# Driver
driver = User.create!(
  email: 'driver@repair.com',
  password: 'password123',
  role: 'driver',
  company_name: 'Logistics Trans',
  phone: '+77070000000'
)

# Create Company Requisites for Client
CompanyRequisite.create!(
  user: client,
  company_name: 'Test Client LLP (Main)',
  bin: '123456789012',
  legal_address: 'Almaty, Dostyk 1',
  actual_address: 'Almaty, Dostyk 1',
  bank_name: 'Halyk Bank',
  iban: 'KZ0000000',
  swift: 'HALYK'
)

puts "Creating Products..."

warehouses = [
  'Кушмурун',
  'Павлодар',
  'Атырау',
  'Шымкент',
  'Аягоз'
]

# 1. Wheelsets (Колесные пары)
thickness_ranges = ['30-34', '35-39', '40-44', '45-49', '50-54', '55-59', '60-64', '64-69', 'СОНК']

thickness_ranges.each do |range|
  warehouses.each do |wh|
    Product.create!(
      name: "Колесная пара (толщина #{range} мм)",
      sku: "WS-#{range.gsub('-', '')}-#{wh[0..2].upcase}",
      price: 180000 + (range.to_i * 1000), # Adjusted price to match image roughly (starts ~180k)
      category: 'Колесные пары',
      stock: rand(3..20),
      warehouse_location: wh,
      characteristics: { thickness: range }
    )
  end
end

# 2. Casting (Литье)
# Боковая рама / Надрессорная балка
casting_types = ['Боковая рама', 'Надрессорная балка']
age_ranges = ['1-5 лет', '6-10 лет', '11-15 лет', '16-20 лет', '21-25 лет']

casting_types.each do |type|
  age_ranges.each do |age|
    warehouses.each do |wh|
      Product.create!(
        name: "#{type} (#{age})",
        sku: "CST-#{type[0..2].upcase}-#{age.gsub(' ', '')}-#{wh[0..2].upcase}",
        price: 90000.00 - (age.to_i * 1000),
        category: 'Литье',
        stock: rand(5..15),
        warehouse_location: wh,
        characteristics: { age: age }
      )
    end
  end
end

# Автосцепка
warehouses.each do |wh|
  Product.create!(
    name: "Автосцепка СА-3 (от 2000-х годов)",
    sku: "CPL-SA3-2000-#{wh[0..2].upcase}",
    price: 45000.00,
    category: 'Литье',
    stock: rand(10..40),
    warehouse_location: wh,
    characteristics: { year: 'от 2000-х' }
  )
end

# 3. Other Parts (Прочие запчасти)
other_parts_list = [
  "Поглощающий аппарат",
  "Тяговый хомут",
  "Триангель",
  "Клин фрикционный",
  "Прокладка подвижная",
  "Пружина наружная",
  "Пружина внутренняя",
  "Центрирующая балочка",
  "Колпак скользуна",
  "Рычаги тормозной рычажной передачи (горизонтальные)",
  "Прокладка сменная",
  "Шкворень",
  "Подвеска тормозного башмака",
  "Упорная плита",
  "Стояночный тормоз",
  "Штурвал стояночного тормоза",
  "Тормозной цилиндр",
  "Рабочая тормозная камера",
  "Авторежим тормозов",
  "Авторегулятор тормозов",
  "Запасной резервуар",
  "Краны концевые",
  "Разобщительные краны",
  "Тормозные тяги",
  "Рычажная передача (вертикальная)",
  "Балка авторежима",
  "Разгрузочное устройство",
  "Разгрузочные люки",
  "Загрузочные люки",
  "Лестница"
]

other_parts_list.each_with_index do |part_name, idx|
  warehouses.each do |wh|
    Product.create!(
      name: part_name,
      sku: "OTH-#{idx + 1}-#{wh[0..2].upcase}",
      price: rand(5000..50000),
      category: 'Прочие запчасти',
      stock: rand(20..100),
      warehouse_location: wh,
      characteristics: {}
    )
  end
end

puts "Database seeded successfully!"
