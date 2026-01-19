class UpdateProductsForCatalogRedesign < ActiveRecord::Migration[7.1]
  def change
    add_column :products, :warehouse_location, :string
    add_column :products, :characteristics, :text, default: "{}"
  end
end
