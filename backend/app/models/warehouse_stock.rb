class WarehouseStock < ApplicationRecord
  belongs_to :warehouse

  validates :product_sku, presence: true
  validates :quantity, presence: true, numericality: { greater_than_or_equal_to: 0 }
end
