class CreateCompanyRequisites < ActiveRecord::Migration[7.1]
  def change
    create_table :company_requisites do |t|
      t.references :user, null: false, foreign_key: true
      t.string :company_name
      t.string :bin
      t.string :inn
      t.string :legal_address
      t.string :actual_address
      t.string :director_name
      t.string :acting_on_basis
      t.string :iban
      t.string :swift
      t.string :kbe

      t.timestamps
    end
  end
end
