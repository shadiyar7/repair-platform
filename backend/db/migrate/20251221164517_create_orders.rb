class CreateOrders < ActiveRecord::Migration[7.1]
  def change
    create_table :orders do |t|
      t.references :user, null: false, foreign_key: true
      t.string :status
      t.decimal :total_amount, precision: 10, scale: 2
      t.integer :driver_id
      t.string :delivery_address
      t.text :delivery_notes

      t.timestamps
    end
  end
end
