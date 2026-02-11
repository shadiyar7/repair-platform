module Api
  module V1
    module Auth
      class RegistrationsController < ApplicationController
        skip_before_action :authenticate_user!, only: [:create]

        def create
          user = User.new(sign_up_params)
          
          if user.save
            # Token generation typically happens on login, but we can sign them in immediately
            sign_in(user)
            token = current_token
            
            # If using cookies
            cookies.signed[:jwt] = {
              value: token,
              httponly: true,
              secure: Rails.env.production?,
              expires: 1.day.from_now
            }

            render json: {
              message: 'Signed up successfully. Please check your email to confirm your account.',
              user: UserSerializer.new(user).serializable_hash,
              token: token 
            }, status: :created
          else
            render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
          end
        end

        def update
          if current_user.update(account_update_params)
            render json: {
              message: 'Profile updated successfully',
              user: UserSerializer.new(current_user).serializable_hash
            }
          else
            render json: { errors: current_user.errors.full_messages }, status: :unprocessable_entity
          end
        end

        private

        def sign_up_params
          params.permit(:email, :password, :password_confirmation, :role)
        end

        def account_update_params
          params.permit(:company_name, :phone, :director_name, :acting_on_basis, :legal_address, :actual_address, :inn, :bin, :iban, :swift)
        end

        def current_token
          request.env['warden-jwt_auth.token']
        end
      end
    end
  end
end
