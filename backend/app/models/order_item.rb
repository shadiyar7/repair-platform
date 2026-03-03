class OrderItem < ApplicationRecord
  serialize :assigned_uids, coder: JSON

  belongs_to :order
  belongs_to :product

  def assign_uids_from_product!
    product.with_lock do
      pool = product.uids || []
      qty = self.quantity || 0
      
      if pool.size < qty
        # Rollback is automatic when raising error inside transaction/with_lock
        raise "Недостаточно уникальных кодов (UID) для товара #{product.name}. Требуется: #{qty}, доступно: #{pool.size}"
      end
      
      assigned = pool.shift(qty)
      self.update!(assigned_uids: assigned)
      product.update!(uids: pool)
    end
  end

  def release_uids!
    return if assigned_uids.blank?
    
    product.with_lock do
      pool = product.uids || []
      pool.concat(assigned_uids)
      product.update!(uids: pool)
      update!(assigned_uids: [])
    end
  end

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
