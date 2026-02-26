class Product < ApplicationRecord
  serialize :characteristics, coder: JSON
  serialize :uids, coder: JSON

  has_many :order_items
  
  validates :nomenclature_code, uniqueness: { scope: :is_deleted }, if: -> { nomenclature_code.present? && !is_deleted }
  
  # Secondary link for stocks management
  has_many :warehouse_stocks, primary_key: :sku, foreign_key: :product_sku
end
