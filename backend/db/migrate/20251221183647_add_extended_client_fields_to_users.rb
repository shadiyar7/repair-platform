class AddExtendedClientFieldsToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :director_name, :string
    add_column :users, :acting_on_basis, :string
    add_column :users, :legal_address, :string
    add_column :users, :actual_address, :string
    add_column :users, :bin, :string
    add_column :users, :iban, :string
    add_column :users, :swift, :string
  end
end
