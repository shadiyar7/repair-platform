# verify_1c_trigger.rb
# Tests the SyncStocksJob execution

puts "\n--- 1. Setup ---"
# Find or create a warehouse requiring sync
wh = Warehouse.find_or_create_by!(external_id_1c: "000000001") do |w|
  w.name = "Trigger Test Warehouse"
  w.address = "Test Zone"
end

puts "Warehouse: #{wh.name} (1C ID: #{wh.external_id_1c})"

puts "\n--- 2. Executing Job ---"
puts "Invoking SyncStocksJob.perform_now(#{wh.id})..."

begin
  SyncStocksJob.perform_now(wh.id)
  puts "✅ Job executed successfully (Check logs for '⚡️ [1C Sync]')."
rescue StandardError => e
  puts "❌ Job failed: #{e.message}"
  puts e.backtrace.first(5)
end
