class CreateProducts < ActiveRecord::Migration[7.1]
  def change
    create_table :products do |t|
      t.string :name
      t.string :sku
      t.decimal :price, precision: 10, scale: 2
      t.string :category
      t.integer :stock
      t.text :description
      t.string :image_url

      t.timestamps
    end
    add_index :products, :sku
  end
end
