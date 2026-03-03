class UpdateOrderFlowAndAddUids < ActiveRecord::Migration[7.1]
  def up
    # 1. Add assigned_uids to order_items
    add_column :order_items, :assigned_uids, :text, default: "[]"

    # 2. Convert orders.status to integer and shift values
    # Rename current status column
    rename_column :orders, :status, :legacy_status
    
    # Add new integer column
    add_column :orders, :status, :integer, default: 0

    # Data migration
    mapping = {
      'cart' => 0,
      'pending_director_signature' => 2,
      'pending_signature' => 3,
      'pending_payment' => 4,
      'payment_review' => 5,
      'paid' => 6,
      'searching_driver' => 7,
      'driver_assigned' => 8,
      'at_warehouse' => 9,
      'in_transit' => 10,
      'delivered' => 11,
      'documents_ready' => 12,
      'completed' => 13
    }

    mapping.each do |old_status, new_value|
      execute "UPDATE orders SET status = #{new_value} WHERE legacy_status = '#{old_status}'"
    end

    # Remove legacy column
    remove_column :orders, :legacy_status
  end

  def down
    add_column :orders, :legacy_status, :string
    
    mapping = {
      0 => 'cart',
      2 => 'pending_director_signature',
      3 => 'pending_signature',
      4 => 'pending_payment',
      5 => 'payment_review',
      6 => 'paid',
      7 => 'searching_driver',
      8 => 'driver_assigned',
      9 => 'at_warehouse',
      10 => 'in_transit',
      11 => 'delivered',
      12 => 'documents_ready',
      13 => 'completed'
    }

    mapping.each do |new_value, old_status|
      execute "UPDATE orders SET legacy_status = '#{old_status}' WHERE status = #{new_value}"
    end
    
    remove_column :orders, :status
    rename_column :orders, :legacy_status, :status
    remove_column :order_items, :assigned_uids
  end
end
