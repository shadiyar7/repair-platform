class AddWarehouseRefToUsers < ActiveRecord::Migration[7.1]
  def change
    add_reference :users, :warehouse, null: true, foreign_key: true
  end
end
