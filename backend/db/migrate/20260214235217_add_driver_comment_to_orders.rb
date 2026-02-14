class AddDriverCommentToOrders < ActiveRecord::Migration[7.1]
  def change
    add_column :orders, :driver_comment, :text
  end
end
