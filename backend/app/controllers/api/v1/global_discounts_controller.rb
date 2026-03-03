module Api
  module V1
    class GlobalDiscountsController < ApplicationController
      def show
        discount = GlobalDiscount.current
        if discount
          render json: discount
        else
          render json: { percent: 0, active: false }
        end
      end
    end
  end
end
