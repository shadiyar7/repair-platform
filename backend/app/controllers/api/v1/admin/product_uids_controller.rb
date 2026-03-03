module Api
  module V1
    module Admin
      class ProductUidsController < ApplicationController
        before_action :authenticate_user!

        def used_uids
          user = current_user
          unless ['director', 'supervisor', 'admin'].include?(user.role)
            return render json: { error: 'Access denied' }, status: :forbidden
          end

          product = Product.find(params[:id])
          
          # Find all order items for this product that have assigned_uids
          order_items = OrderItem.includes(order: [:user, :company_requisite])
                                 .where(product_id: product.id)
                                 .where.not(assigned_uids: [nil, "[]", "", "[\"\"]", "[]\n"])

          history = []

          order_items.each do |item|
            next if item.assigned_uids.blank?
            
            # Parse if it's a string, though ActiveRecord serialize should handle it
            uids = item.assigned_uids.is_a?(String) ? JSON.parse(item.assigned_uids) : item.assigned_uids
            
            # Filter out empty strings if any crept in
            uids = uids.reject(&:blank?)
            next if uids.empty?

            order = item.order
            client_name = order.company_requisite&.company_name&.gsub(/\(Main\)/, '')&.strip || order.user&.company_name&.gsub(/\(Main\)/, '')&.strip || order.user&.email || 'Неизвестный клиент'

            uids.each do |uid|
              history << {
                uid: uid,
                order_id: order.id,
                order_status: order.status,
                client_name: client_name,
                price: item.price || product.price,
                assigned_at: item.updated_at
              }
            end
          end

          # Sort by most recently assigned
          history.sort_by! { |h| h[:assigned_at] }.reverse!

          render json: { 
            data: {
              product_id: product.id,
              product_name: product.name,
              total_used: history.size,
              history: history 
            }
          }
        end
      end
    end
  end
end
