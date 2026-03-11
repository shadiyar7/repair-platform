class Order < ApplicationRecord
  include AASM
  
  has_one_attached :document
  has_one_attached :payment_receipt

  belongs_to :user
  belongs_to :company_requisite, optional: true
  # driver_id foreign key to users is deprecated as drivers are now just text fields (no login)
  # belongs_to :driver, class_name: 'User', optional: true
  belongs_to :completed_by, class_name: 'User', optional: true

  has_many :order_items, dependent: :destroy
  has_many :products, through: :order_items

  enum status: {
    cart: 0,
    contract_review: 1,
    pending_director_signature: 2,
    pending_signature: 3,
    pending_payment: 4,
    payment_review: 5,
    paid: 6,
    searching_driver: 7,
    driver_assigned: 8,
    at_warehouse: 9,
    in_transit: 10,
    delivered: 11,
    documents_ready: 12,
    completed: 13,
    cancelled: 99
  }

  accepts_nested_attributes_for :order_items

  before_create :generate_smart_link_token

  def generate_smart_link_token
    self.smart_link_token = SecureRandom.urlsafe_base64(32)
  end

  def calculate_total_amount
    self.base_amount = order_items.sum { |item| (item.price || item.product&.price || 0) * (item.quantity || 0) }
    
    # Apply global discount if order is in cart, or if not yet saved
    if (new_record? || cart?) && GlobalDiscount.current
      self.discount_percent = GlobalDiscount.current.percent
    end

    if self.discount_percent.to_f > 0
      self.discount_amount = self.base_amount * (self.discount_percent / 100.0)
    else
      self.discount_amount = 0
    end

    discounted_base = self.base_amount - self.discount_amount
    self.vat_amount = discounted_base * 0.16
    self.total_amount = discounted_base + self.vat_amount
  end

  def update_total!
    calculate_total_amount
    save!
  end

  private

    aasm column: :status, enum: true do
      state :cart, initial: true
      state :contract_review
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
      state :cancelled

      event :checkout do
        transitions from: :cart, to: :contract_review
      end

      event :submit_requisites do
        transitions from: :cart, to: :contract_review
      end

      event :confirm_contract do
        transitions from: :contract_review, to: :pending_director_signature, after: :assign_contract_number
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
        transitions from: [:in_transit, :delivered, :documents_ready], to: :completed
      end

      event :cancel do
        transitions from: [:contract_review, :pending_director_signature], to: :cancelled, after: :release_item_uids
      end
    end

    def release_item_uids
      order_items.each(&:release_uids!)
    end

    def set_director_signed_at
      touch(:director_signed_at)
    end


    after_commit :send_status_emails, on: :update, if: :saved_change_to_status?

    private

    def send_status_emails
      begin
        case status
        when 'contract_review'
          # If transitioning from cart -> contract_review, order is placed.
          if saved_change_to_status[0] == 'cart'
            OrderMailer.with(order: self).order_created.deliver_later
          end
        when 'pending_director_signature'
          OrderMailer.with(order: self).pending_director_signature.deliver_later
        when 'pending_payment'
          # Client has signed
          OrderMailer.with(order: self).client_signed.deliver_later
        when 'searching_driver'
          # Searching driver is reached via upload_receipt or confirm_payment.
          # We don't send emails here to avoid duplicates.
          # upload_receipt sends receipt_uploaded manually.
          # confirm_payment sends payment_confirmed manually.
        when 'driver_assigned', 'at_warehouse', 'in_transit'
          OrderMailer.with(order: self).driver_status_update.deliver_later
        when 'delivered'
          OrderMailer.with(order: self).order_delivered.deliver_later
        end
      rescue => e
        Rails.logger.error "Failed to send status email for order ##{id} (status: #{status}): #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
      end
    end
    
  public

    def is_existing_client?
      # An EXISTING client is a Customer who has at least one previous order that passed the "Client signed" stage.
      # "Client signed" means status is pending_payment (4) or higher.
      user.orders.where('status >= ?', 4).where.not(id: self.id).exists?
    end

    def assigned_uids_map
      order_items.includes(:product).each_with_object({}) do |item, hash|
        hash[item.product.name] = item.assigned_uids
      end
    end

    def assign_contract_number
      return if self.contract_number.present? || is_existing_client?

      current_month = Date.today.month
      current_year = Date.today.year

      max_sequence = Order.where(
        "EXTRACT(MONTH FROM created_at) = ? AND EXTRACT(YEAR FROM created_at) = ?",
        current_month, current_year
      ).maximum(:new_client_contract_sequence) || 0

      next_sequence = max_sequence + 1

      self.new_client_contract_sequence = next_sequence
      self.contract_number = "DM-#{current_month.to_s.rjust(2, '0')}-#{current_year}-#{next_sequence}"
    end
end
