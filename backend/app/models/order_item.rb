class OrderItem < ApplicationRecord
  belongs_to :order
  belongs_to :product

  after_save :update_order_total
  after_destroy :update_order_total

  private

  def update_order_total
    order.update_total!
  end
end
