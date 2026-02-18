module Api
  module V1
    class SmartLinksController < ApplicationController
      skip_before_action :authenticate_user!, only: [:show, :update_location]

      # GET /api/v1/smart_links/:token
      def show
        @order = Order.find_by!(smart_link_token: params[:token])
        
        # Determine Warehouse Location (Latitude/Longitude)
        # Ideally, Warehouse model should have lat/lng. For now, hardcoding Almaty center or fetching from 1C if available.
        # Or we use the warehouse address string.
        
        render json: {
          id: @order.id,
          status: @order.status,
          city: @order.city,
          delivery_address: @order.delivery_address, # Destination
          driver_name: @order.driver_name,
          driver_phone: @order.driver_phone,
          driver_car_number: @order.driver_car_number,
          current_lat: @order.current_lat,
          current_lng: @order.current_lng,
          warehouse_name: @order.order_items.first&.product&.warehouse_location, # Origin Name
          # We might need warehouse coordinates for routing start point if we want to show full route
        }
      end

      # POST /api/v1/smart_links/:token/location
      # Updates driver location
      # Body: { lat: 43.2, lng: 76.9 }
      def update_location
        @order = Order.find_by!(smart_link_token: params[:token])
        
        if @order.update(current_lat: params[:lat], current_lng: params[:lng])
          render json: { status: 'success', lat: @order.current_lat, lng: @order.current_lng }
        else
          render json: { error: 'Failed to update location' }, status: :unprocessable_entity
        end
      end
    end
  end
end
