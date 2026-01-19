class AddSmartLinkTokenToOrders < ActiveRecord::Migration[7.1]
  def change
    add_column :orders, :smart_link_token, :string
    add_index :orders, :smart_link_token
  end
end
