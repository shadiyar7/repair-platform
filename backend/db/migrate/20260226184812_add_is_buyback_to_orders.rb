class AddIsBuybackToOrders < ActiveRecord::Migration[7.1]
  def change
    add_column :orders, :is_buyback, :boolean, default: false
  end
end
