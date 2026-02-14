class WarehouseMailer < ApplicationMailer
  default from: 'notifications@repair-platform.com'

  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.warehouse_mailer.driver_assigned.subject
  #
  def driver_assigned(order)
    @order = order
    mail(
      to: 'warehouse@example.com', # Replace with real email
      subject: "DRIVER ASSIGNED: Order ##{order.id}"
    )
  end
end
