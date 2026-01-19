class CompanyRequisite < ApplicationRecord
  belongs_to :user

  validates :company_name, :bin, :legal_address, :actual_address, presence: true
  validates :bin, length: { is: 12 }
end
