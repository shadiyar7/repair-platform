class Product < ApplicationRecord
  serialize :characteristics, coder: JSON
  serialize :uids, coder: JSON

  has_many :order_items
  
  # Secondary link for stocks management
  has_many :warehouse_stocks, primary_key: :sku, foreign_key: :product_sku
end
