module Api
  module V1
    class CommercialProposalsController < ApplicationController
      # Allow access without auth for now as it might be used from cart
      # skip_before_action :authenticate_user!, raise: false 

      def create
        items_params = params[:items] # [{ id: 1, quantity: 5 }, ...]
        
        if items_params.blank?
          render json: { error: 'No items provided' }, status: :bad_request
          return
        end

        # Fetch products to ensure we use current prices and names from DB
        product_ids = items_params.map { |i| i[:id] }
        products = Product.where(id: product_ids).index_by(&:id)

        # Prepare line items for the service
        products_data = []
        
        items_params.each do |item|
          product = products[item[:id]] || products[item[:id].to_i] # handle string/int ids
          next unless product
          
          qty = item[:quantity].to_i
          total = qty * product.price
          
          products_data << {
            name: product.name,
            quantity: qty,
            price: product.price,
            total: total
          }
        end

        if products_data.empty?
           render json: { error: 'No valid products found' }, status: :unprocessable_entity
           return
        end

        # Generate PDF using the service
        service = CommercialProposalService.new(products_data)
        pdf_data = service.generate

        send_data pdf_data,
          filename: "KP_Dynamix_#{Date.current.strftime('%d.%m.%Y')}.pdf",
          type: "application/pdf",
          disposition: "attachment"
      end
    end
  end
end
