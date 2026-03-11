class AddDisplayFieldsToWarehouses < ActiveRecord::Migration[7.1]
  def change
    add_column :warehouses, :display_name, :string
    add_column :warehouses, :is_active, :boolean, default: true

    reversible do |dir|
      dir.up do
        Warehouse.reset_column_information
        # Hide any warehouses that are test, brak, in transit
        Warehouse.find_each do |w|
          if w.name.downcase.include?('тест') || w.name.downcase.include?('test') || w.name.downcase.include?('брак') || w.name.downcase.include?('пути')
            w.update_columns(is_active: false)
          end
        end
      end
    end
  end
end
