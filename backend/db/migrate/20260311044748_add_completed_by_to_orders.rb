class AddCompletedByToOrders < ActiveRecord::Migration[7.1]
  def change
    add_column :orders, :completed_by_id, :integer
    add_column :orders, :completed_at, :datetime
  end
end
