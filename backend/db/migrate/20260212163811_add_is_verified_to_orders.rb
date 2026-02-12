class AddIsVerifiedToOrders < ActiveRecord::Migration[7.1]
  def change
    add_column :orders, :is_verified, :boolean
  end
end
