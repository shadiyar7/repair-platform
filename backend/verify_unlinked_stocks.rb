# verify_unlinked_stocks.rb

puts "\n--- 1. Setup ---"
wh_id = 888
warehouse = Warehouse.find_or_create_by!(external_id_1c: wh_id) do |w|
  w.name = "Unlinked Test Warehouse"
  w.address = "Virtual Zone 2"
end
puts "Warehouse: #{warehouse.name}"

# Create an ORPHAN stock (no corresponding Product)
orphan_sku = "ORPHAN-#{Time.now.to_i}"
stock = warehouse.warehouse_stocks.find_or_initialize_by(product_sku: orphan_sku)
stock.quantity = 100
stock.synced_at = Time.now
stock.save!
puts "Created Orphan Stock: #{orphan_sku}"

# Create a LINKED stock (has Product)
linked_sku = "LINKED-#{Time.now.to_i}"
product = Product.create!(
  sku: linked_sku, 
  name: "Linked Product", 
  price: 100, 
  category: "Другое", 
  is_active: true
)
stock2 = warehouse.warehouse_stocks.find_or_initialize_by(product_sku: linked_sku)
stock2.quantity = 50
stock2.synced_at = Time.now
stock2.save!
puts "Created Linked Stock: #{linked_sku}"

puts "\n--- 2. Call Endpoint Logic ---"
# Simulate the Controller Logic
scope = WarehouseStock.where(warehouse_id: warehouse.id)
existing_skus = Product.pluck(:sku)
unlinked_stocks = scope.where.not(product_sku: existing_skus)

puts "Found #{unlinked_stocks.count} unlinked items."

found = unlinked_stocks.find { |s| s.product_sku == orphan_sku }

if found
  puts "✅ SUCCESS: Orphan SKU '#{orphan_sku}' was returned."
else
  puts "❌ FAILURE: Orphan SKU was NOT returned."
end

if unlinked_stocks.any? { |s| s.product_sku == linked_sku }
  puts "❌ FAILURE: Linked SKU '#{linked_sku}' WAS returned (it should not be)."
else
  puts "✅ SUCCESS: Linked SKU correctly excluded."
end
