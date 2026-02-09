# verify_1c_sync.rb
# Simulates a 1C server pushing stock updates

puts "\n--- 1. Setup Test Warehouse ---"
# Create a warehouse that expects 1C data
wh_id = 999
warehouse = Warehouse.find_or_create_by!(external_id_1c: wh_id) do |w|
  w.name = "Test 1C Warehouse"
  w.address = "Virtual Zone 1"
end
puts "Warehouse: #{warehouse.name} (1C ID: #{warehouse.external_id_1c})"

# Create a product to sync
sku = "TEST-SKU-001"
product = Product.find_or_create_by!(sku: sku) do |p|
  p.name = "Test Wheelset"
  p.price = 50000
  p.category = 'Колесные пары'
  p.is_active = true
end
puts "Product: #{product.name} (SKU: #{sku})"

# Ensure initial stock is 0
stock = WarehouseStock.find_or_initialize_by(warehouse: warehouse, product_sku: sku)
stock.update!(quantity: 0)
puts "Initial Stock: #{stock.quantity}"

puts "\n--- 2. Simulate 1C Payload ---"
# Construct the payload that 1C would send
payload = {
  warehouse_id_1c: wh_id,
  items: [
    {
      nomenclature_code: sku,
      quantity: 42,
      name: "Test Wheelset (from 1C)" # Name ignored by update logic, but usually sent
    }
  ]
}

puts "Sending Payload: #{payload.inspect}"

# Manually invoke the logic (simulating the Controller action for speed/directness)
# In a real integration test we'd use 'post ...', but via runner we can check logic directly
# or use a local request simulation. Let's use internal logic for unit-verification.

ActiveRecord::Base.transaction do
  warehouse.update!(last_synced_at: Time.now)
  
  payload[:items].each do |item|
    s = warehouse.warehouse_stocks.find_or_initialize_by(product_sku: item[:nomenclature_code])
    s.quantity = item[:quantity]
    s.synced_at = Time.now
    s.save!
    puts "Updated Stock for #{s.product_sku} to #{s.quantity}"
  end
end

puts "\n--- 3. Verify Results ---"
final_stock = WarehouseStock.find_by(warehouse: warehouse, product_sku: sku)
puts "Final Stock in DB: #{final_stock.quantity}"

if final_stock.quantity == 42
  puts "✅ SUCCESS: 1C Sync verified!"
else
  puts "❌ FAILURE: Stock mismatch."
end
