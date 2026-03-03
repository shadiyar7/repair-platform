class GenerateContractJob < ApplicationJob
  queue_as :default

  retry_on StandardError, wait: 5.seconds, attempts: 3

  def perform(order_id)
    order = Order.find(order_id)
    OrderContractService.new(order).call
  end
end
