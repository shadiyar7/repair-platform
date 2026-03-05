module Api
  module V1
    module Admin
      class DebugController < ApplicationController
        before_action :authenticate_request!
        before_action :authorize_admin!

        def send_test_emails
          # Find any random order to use as a mock, or fallback to a dummy if db is empty
          order = Order.last

          unless order
            render json: { error: "No orders found in DB to mock the email." }, status: :unprocessable_entity
            return
          end

          begin
            # Broadcast all 7 emails to the test recipient (shadiyar)
            OrderMailer.with(order: order, is_test: true).order_created.deliver_later
            OrderMailer.with(order: order, is_test: true).pending_director_signature.deliver_later
            OrderMailer.with(order: order, is_test: true).client_signed.deliver_later
            OrderMailer.with(order: order, is_test: true).receipt_uploaded.deliver_later
            OrderMailer.with(order: order, is_test: true).payment_confirmed.deliver_later
            OrderMailer.with(order: order, is_test: true, status_text: "Водитель в пути").driver_status_update.deliver_later
            OrderMailer.with(order: order, is_test: true).order_delivered.deliver_later

            render json: { message: "7 тестовых писем успешно отправлены на shadiyar.alakhan@gmail.com" }, status: :ok
          rescue => e
            render json: { error: e.message }, status: :internal_server_error
          end
        end

        private

        def authorize_admin!
          unless @current_user&.role == 'admin'
            render json: { error: 'Access denied' }, status: :forbidden
          end
        end
      end
    end
  end
end
