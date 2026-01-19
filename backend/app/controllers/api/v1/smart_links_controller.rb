module Api
  module V1
    class SmartLinksController < ApplicationController
      skip_before_action :authenticate_user!
      before_action :set_order, only: [:show, :update_location]

      # GET /api/v1/smart_links/:token
      def show
        render json: {
          order: OrderSerializer.new(@order).serializable_hash,
          pickup_point: { lat: 43.238949, lng: 76.889709 }, # Mock coordinates (Almaty)
          delivery_point: { lat: 51.169392, lng: 71.449074 } # Mock coordinates (Astana)
        }
      end

      # POST /api/v1/smart_links/:token/location
      def update_location
        # Here we would update the driver's current location in Redis or DB
        # For now, just logging it
        Rails.logger.info "Driver location update: #{params[:lat]}, #{params[:lng]}"
        render json: { status: 'success' }
      end

      private

      def set_order
        @order = Order.find_by!(smart_link_token: params[:token])
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Invalid token' }, status: :not_found
      end
    end
  end
end
