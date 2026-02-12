namespace :orders do
  desc "Fix zero prices in order items based on product prices"
  task fix_prices: :environment do
    orders = Order.preload(order_items: :product)
    
    orders.find_each do |order|
      next unless order.order_items.any?

      updated = false
      total_check = 0
      
      order.order_items.each do |item|
        if item.price.to_f.zero? && item.product
          old_price = item.price
          # Fallback to product price
          new_price = item.product.price || 0
          
          item.update_columns(price: new_price)
          puts "[Order ##{order.id}] Item #{item.id} (Product: #{item.product.name}) price updated: #{old_price} -> #{new_price}"
          updated = true
        else
          puts "[Order ##{order.id}] Item #{item.id} has valid price: #{item.price}"
        end
        
        total_check += (item.quantity * item.price)
      end

      if updated
        # Recalculate total
        old_total = order.total_amount
        order.update_columns(total_amount: total_check)
        puts "[Order ##{order.id}] Total updated: #{old_total} -> #{total_check}"
        
        # Purge old PDF if exists so it can be regenerated with new prices
        if order.document.attached?
          order.document.purge 
          puts "[Order ##{order.id}] Purged old contract PDF."
        end
      end
    end
  end
end
