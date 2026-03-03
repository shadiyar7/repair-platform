class CreateGlobalDiscounts < ActiveRecord::Migration[7.1]
  def change
    create_table :global_discounts do |t|
      t.decimal :percent
      t.datetime :valid_until
      t.boolean :active

      t.timestamps
    end
  end
end
