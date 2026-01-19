module Logistics
  class DellaMockService
    def initialize(order)
      @order = order
    end

    def call
      # Simulate external API call latency
      sleep 1.5

      # Mock success response
      {
        status: 'success',
        della_order_id: "DELLA-#{rand(10000..99999)}",
        estimated_price: calculate_mock_price,
        distance_km: rand(300..1200),
        message: 'Request successfully created on Della.kz (Mock)'
      }
    end

    private

    def calculate_mock_price
      distance = rand(300..1200)
      price_per_km = 900
      distance * price_per_km
    end
  end
end
