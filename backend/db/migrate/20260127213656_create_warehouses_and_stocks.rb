class CreateWarehousesAndStocks < ActiveRecord::Migration[7.1]
  def change
    create_table :warehouses do |t|
      t.string :name
      t.integer :external_id_1c, index: true
      t.string :address

      t.timestamps
    end

    create_table :warehouse_stocks do |t|
      t.references :warehouse, null: false, foreign_key: true
      t.string :product_sku, index: true
      t.decimal :quantity, precision: 10, scale: 2, default: 0.0
      t.datetime :synced_at

      t.timestamps
    end
    
    add_index :warehouse_stocks, [:warehouse_id, :product_sku], unique: true
  end
end
