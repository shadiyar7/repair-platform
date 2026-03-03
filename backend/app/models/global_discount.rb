class GlobalDiscount < ApplicationRecord
  # Ensure only one active discount at a time
  validates :percent, presence: true, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }
  
  def self.current
    # Return the first active discount that hasn't expired
    where(active: true)
      .where('valid_until IS NULL OR valid_until > ?', Time.current)
      .first
  end
end
