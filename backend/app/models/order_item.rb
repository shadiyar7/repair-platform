class OrderItem < ApplicationRecord
  belongs_to :order
  belongs_to :product

  after_save :update_order_total
  after_destroy :update_order_total

  before_save :set_price

  private

  def set_price
    self.price = product.price if price.blank? && product.present?
  end

  def update_order_total
    order.update_total!
  end
end
