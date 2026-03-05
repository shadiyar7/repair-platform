class AddContractSequenceToOrders < ActiveRecord::Migration[7.1]
  def change
    add_column :orders, :new_client_contract_sequence, :integer
    add_column :orders, :contract_number, :string
  end
end
