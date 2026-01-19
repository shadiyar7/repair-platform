module Logistics
  class DriverFinder
    def initialize(order)
      @order = order
    end

    def call
      # This would typically be a background job.
      # For the demo, we'll simulate an immediate "search started" response
      # and schedule a job to "find" the driver after a delay.
      
      # @order.update(status: 'searching_driver')
      @order.find_driver! if @order.may_find_driver?
      
      # Simulate finding a driver after 5 seconds
      # In a real app, this would be Sidekiq. Here we'll just return success
      # and let the frontend poll or we can cheat and update it immediately for simple demo flow
      # but the requirement says "Timer waiting", so let's keep it in 'driver_search'
      # and have a separate endpoint to "simulate_driver_found" or use a job.
      
      # For simplicity in this MVP without Sidekiq/Redis:
      # We will return success, and the frontend will poll.
      # The "finding" logic will be triggered by a separate "admin/debug" endpoint 
      # OR we can just randomly find one on the next poll if enough time passed.
      
      {
        success: true,
        message: "Searching for drivers near #{@order.delivery_address}..."
      }
    end

    def self.simulate_driver_found(order)
      driver = User.where(role: 'driver').sample
      return unless driver

      order.update(
        driver: driver,
        status: 'driver_assigned'
      )
    end
  end
end
