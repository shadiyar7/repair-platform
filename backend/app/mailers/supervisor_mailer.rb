class SupervisorMailer < ApplicationMailer
  default from: 'notifications@repair-platform.com'

  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.supervisor_mailer.new_payment_receipt.subject
  #
  def new_payment_receipt(order)
    @order = order
    @receipt_url = Rails.application.routes.url_helpers.rails_blob_url(order.payment_receipt, host: 'repair-platform.onrender.com')
    
    mail(
      to: 'supervisor@example.com', # Replace with real email or logic
      subject: "NEW ORDER PAID: ##{order.id} - #{order.city}"
    )
  end
end
