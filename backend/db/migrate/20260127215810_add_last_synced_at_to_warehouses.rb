class AddLastSyncedAtToWarehouses < ActiveRecord::Migration[7.1]
  def change
    add_column :warehouses, :last_synced_at, :datetime
  end
end
