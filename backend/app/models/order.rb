class Order < ApplicationRecord
  include AASM
  
  has_one_attached :document
  has_one_attached :payment_receipt

  belongs_to :user
  belongs_to :company_requisite, optional: true    
  belongs_to :company_requisite, optional: true    
  # driver_id foreign key to users is deprecated as drivers are now just text fields (no login)
  # belongs_to :driver, class_name: 'User', optional: true
  has_many :order_items, dependent: :destroy
  has_many :products, through: :order_items

  accepts_nested_attributes_for :order_items

  before_create :generate_smart_link_token

  def generate_smart_link_token
    self.smart_link_token = SecureRandom.urlsafe_base64(32)
  end

  def calculate_total_amount
    self.total_amount = order_items.sum { |item| (item.price || item.product&.price || 0) * (item.quantity || 0) }
  end

  def update_total!
    calculate_total_amount
    save!
  end

  private

    aasm column: :status do
      state :cart, initial: true
      state :pending_director_signature
      state :pending_signature
      state :pending_payment
      state :payment_review # Deprecated but kept for legacy orders
      state :paid # Deprecated but kept for legacy orders
      state :searching_driver
      state :driver_assigned
      state :at_warehouse
      state :in_transit
      state :delivered
      state :documents_ready
      state :completed

      event :checkout do
        transitions from: :cart, to: :pending_director_signature
      end

      event :submit_requisites do
        transitions from: :cart, to: :pending_director_signature
      end

      # prepare_contract is now redundant if we skip requisites_selected, 
      # but we can keep it for manual transitions if needed or remove it. 
      # Removing it to clean up as requested "remove it entirely".
      
      event :director_sign do
        transitions from: :pending_director_signature, to: :pending_signature, after: :set_director_signed_at
      end

      event :sign_contract do
        transitions from: :pending_signature, to: :pending_payment
      end

      event :upload_receipt do
        transitions from: [:pending_payment, :payment_review], to: :searching_driver
      end

      # Admin confirms payment manually or system auto-confirms
      event :confirm_payment do
        transitions from: [:payment_review, :searching_driver], to: :searching_driver
      end

      event :pay do
        transitions from: [:pending_payment, :payment_review], to: :searching_driver
      end

      event :find_driver do
        transitions from: [:paid, :payment_review], to: :searching_driver
      end

      event :assign_driver do
        transitions from: [:searching_driver, :payment_review, :paid], to: :driver_assigned
      end

      event :driver_arrived do
        transitions from: :driver_assigned, to: :at_warehouse
      end

      event :start_trip do
        transitions from: :at_warehouse, to: :in_transit
      end

      event :deliver do
        transitions from: :in_transit, to: :delivered
      end

      event :generate_documents do
        transitions from: :delivered, to: :documents_ready
      end

      event :complete do
        transitions from: :documents_ready, to: :completed
      end
    end

    def set_director_signed_at
      touch(:director_signed_at)
    end

    after_commit do
      if saved_change_to_status? && status == 'pending_director_signature'
        begin
          DirectorMailer.signature_request(self).deliver_later
        rescue => e
          Rails.logger.error "Failed to send Director email: #{e.message}"
        end
      end
    end
end
