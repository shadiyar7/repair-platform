class AddIdocsFieldsToOrders < ActiveRecord::Migration[7.1]
  def change
    add_column :orders, :idocs_document_id, :string
    add_column :orders, :idocs_status, :string
  end
end
