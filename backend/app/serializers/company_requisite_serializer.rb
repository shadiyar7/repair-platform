class CompanyRequisiteSerializer
  include JSONAPI::Serializer
  attributes :company_name, :bin, :legal_address, :actual_address, 
             :director_name, :acting_on_basis, :inn, 
             :iban, :swift, :kbe, :bank_name, :created_at, :updated_at

  belongs_to :user
end
