class AddNomenclatureCodeToWarehouseStocks < ActiveRecord::Migration[7.1]
  def change
    add_column :warehouse_stocks, :nomenclature_code, :string
  end
end
