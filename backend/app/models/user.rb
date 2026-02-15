class User < ApplicationRecord
  include Devise::JWT::RevocationStrategies::JTIMatcher

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :jwt_authenticatable, :confirmable, jwt_revocation_strategy: self

  enum role: { client: 'client', admin: 'admin', warehouse: 'warehouse', driver: 'driver', director: 'director' }

  validates :role, presence: true
  
  # Client-specific validations
  with_options if: :client? do |client|
    # Only validate legacy fields if they are actually used (which they shouldn't be for new flows)
    # But for now, we keep them optional or only validate if not empty to support legacy data.
    # The requirement is: Internal staff (Admin, etc) do NOT need these.
    
    # We can just skip validations for non-clients.
  end

  # Validate job_title for internal staff
  validates :job_title, presence: true, unless: :client?

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
