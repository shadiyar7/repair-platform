class Warehouse < ApplicationRecord
  has_many :warehouse_stocks, dependent: :destroy

  validates :name, presence: true
  validates :external_id_1c, presence: true, uniqueness: true, numericality: { only_integer: true }
end
