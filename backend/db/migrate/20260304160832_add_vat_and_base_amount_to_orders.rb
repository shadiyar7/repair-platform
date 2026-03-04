class AddVatAndBaseAmountToOrders < ActiveRecord::Migration[7.1]
  def change
    add_column :orders, :base_amount, :decimal
    add_column :orders, :vat_amount, :decimal
  end
end
