class AddFieldsToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :role, :string
    add_column :users, :company_name, :string
    add_column :users, :inn, :string
    add_column :users, :phone, :string
  end
end
