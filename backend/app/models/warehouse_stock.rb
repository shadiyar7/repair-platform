class WarehouseStock < ApplicationRecord
  belongs_to :warehouse

  validates :quantity, presence: true, numericality: { greater_than_or_equal_to: 0 }
  
  validates :product_sku, presence: true, unless: -> { nomenclature_code.present? }

end
