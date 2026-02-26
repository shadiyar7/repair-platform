class AddDeletionAndUidsToProducts < ActiveRecord::Migration[7.1]
  def change
    add_column :products, :is_deleted, :boolean, default: false
    add_column :products, :uids, :text, default: "[]"
  end
end
