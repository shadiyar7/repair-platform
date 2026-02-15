module Api
  module V1
    class AnalyticsController < ApplicationController
      before_action :authenticate_user!
      before_action :authorize_analytics

      def dashboard
        # 1. KPI Cards
        total_revenue = Order.where(status: ['paid', 'driver_assigned', 'at_warehouse', 'in_transit', 'delivered', 'completed']).sum(:total_amount)
        active_orders_count = Order.where.not(status: ['completed', 'cancelled', 'cart']).count
        avg_check = Order.where(status: ['completed', 'paid']).average(:total_amount) || 0

        # 2. Sales Trend (Last 7 Days)
        sales_trend = (0..6).map do |i|
          date = i.days.ago.to_date
          {
            date: date.strftime("%d.%m"),
            amount: Order.where(created_at: date.beginning_of_day..date.end_of_day).sum(:total_amount)
          }
        end.reverse

        # 3. Top Products (by Quantity)
        top_products = OrderItem.joins(:product)
                                .group('products.name')
                                .order('sum_quantity DESC')
                                .limit(5)
                                .sum(:quantity)
                                .map { |name, qty| { name: name, quantity: qty } }

        # 4. Product Category Split (Revenue)
        category_split = OrderItem.joins(:product)
                                  .group('products.category')
                                  .sum('order_items.price * order_items.quantity')
                                  .map { |cat, rev| { name: cat, value: rev } }

        render json: {
          kpi: {
            total_revenue: total_revenue,
            active_orders: active_orders_count,
            avg_check: avg_check
          },
          charts: {
            sales_trend: sales_trend,
            top_products: top_products,
            category_split: category_split
          }
        }
      end

      private

      def authorize_analytics
        unless ['director', 'admin'].include?(current_user.role)
          render json: { error: 'Unauthorized' }, status: :forbidden
        end
      end
    end
  end
end
