class AddCompanyRequisiteToOrders < ActiveRecord::Migration[7.1]
  def change
    add_reference :orders, :company_requisite, null: true, foreign_key: true
  end
end
