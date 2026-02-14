class AddLocationToOrders < ActiveRecord::Migration[7.1]
  def change
    add_column :orders, :current_lat, :float
    add_column :orders, :current_lng, :float
  end
end
