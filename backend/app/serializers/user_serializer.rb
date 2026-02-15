class UserSerializer
  include JSONAPI::Serializer
  attributes :id, :email, :role, :job_title, :company_name, :inn, :phone, :director_name, :acting_on_basis, :legal_address, :actual_address, :bin, :iban, :swift
end
