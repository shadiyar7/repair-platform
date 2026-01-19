class AddBankNameToCompanyRequisites < ActiveRecord::Migration[7.1]
  def change
    add_column :company_requisites, :bank_name, :string
  end
end
