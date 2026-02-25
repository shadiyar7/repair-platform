class AddIsActiveToCompanyRequisites < ActiveRecord::Migration[7.1]
  def change
    add_column :company_requisites, :is_active, :boolean, default: true, null: false
  end
end
