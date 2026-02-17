class AddNomenclatureNameToWarehouseStocks < ActiveRecord::Migration[7.1]
  def change
    add_column :warehouse_stocks, :nomenclature_name, :string
  end
end
