require_relative 'config/environment'
o = Order.last
puts "ID: #{o.id}"
puts "Base: #{o.base_amount.to_f}"
puts "Discount: #{o.discount_amount.to_f}"
puts "VAT: #{o.vat_amount.to_f}"
puts "Total: #{o.total_amount.to_f}"
