class User < ApplicationRecord
  include Devise::JWT::RevocationStrategies::JTIMatcher

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :jwt_authenticatable, :confirmable, jwt_revocation_strategy: self

  enum role: { client: 'client', admin: 'admin', warehouse: 'warehouse', driver: 'driver', director: 'director' }

  validates :role, presence: true
  
  # Client-specific validations (Legacy - moving to CompanyRequisite)
  # with_options if: :client? do |client|
  #   client.validates :company_name, presence: true
  #   client.validates :director_name, presence: true
  #   client.validates :acting_on_basis, presence: true
  #   client.validates :legal_address, presence: true
  #   client.validates :actual_address, presence: true
  #   client.validates :bin, presence: true
  #   client.validates :iban, presence: true
  #   client.validates :swift, presence: true
  # end

  has_many :company_requisites, dependent: :destroy
  has_many :orders, dependent: :destroy

  # OTP Logic
  def generate_otp!
    self.otp_attempt = Rails.env.development? || Rails.env.test? ? '111111' : rand(100000..999999).to_s
    self.otp_sent_at = Time.current
    save!
  end

  def verify_otp(code)
    return false if otp_sent_at < 5.minutes.ago
    code == otp_attempt
  end

  # Override Devise's default confirmation email to do nothing
  # We will send our own OTP email manually in Controller
  def send_confirmation_instructions
    # Do nothing
  end

  # Temporary: Keep legacy fields accessible but prefer CompanyRequisite
  # In future steps we will migrate data and remove these columns
end
