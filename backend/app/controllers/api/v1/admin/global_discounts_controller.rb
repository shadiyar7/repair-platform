module Api
  module V1
    module Admin
      class GlobalDiscountsController < ApplicationController
        before_action :authenticate_request!
        before_action :authorize_admin!

        def show
          discount = GlobalDiscount.first
          render json: discount || {}
        end

        def create
          discount = GlobalDiscount.first_or_initialize
          if discount.update(discount_params)
            render json: discount
          else
            render json: { errors: discount.errors.full_messages }, status: :unprocessable_entity
          end
        end

        private

        def discount_params
          params.require(:global_discount).permit(:percent, :valid_until, :active)
        end

        def authorize_admin!
          unless @current_user&.admin? || @current_user&.director?
            render json: { error: 'Access denied' }, status: :forbidden
          end
        end
      end
    end
  end
end
