class AddDiscountToOrders < ActiveRecord::Migration[7.1]
  def change
    add_column :orders, :discount_percent, :decimal
    add_column :orders, :discount_amount, :decimal
  end
end
