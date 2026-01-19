class AddDriverDetailsToOrders < ActiveRecord::Migration[7.1]
  def change
    add_column :orders, :driver_name, :string
    add_column :orders, :driver_phone, :string
    add_column :orders, :driver_car_number, :string
    add_column :orders, :driver_arrival_time, :datetime
    add_column :orders, :director_signed_at, :datetime
  end
end
