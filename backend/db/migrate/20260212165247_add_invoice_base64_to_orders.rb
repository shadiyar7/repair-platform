class AddInvoiceBase64ToOrders < ActiveRecord::Migration[7.1]
  def change
    add_column :orders, :invoice_base64, :text
  end
end
