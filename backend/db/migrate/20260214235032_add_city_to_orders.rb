class AddCityToOrders < ActiveRecord::Migration[7.1]
  def change
    add_column :orders, :city, :string
  end
end
