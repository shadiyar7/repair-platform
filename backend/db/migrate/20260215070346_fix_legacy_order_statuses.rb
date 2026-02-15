class FixLegacyOrderStatuses < ActiveRecord::Migration[7.1]
  def up
    Order.where(status: ['payment_review', 'paid']).update_all(status: 'searching_driver')
  end

  def down
  end
end
