module Api
  module V1
    module Auth
      class SessionsController < ApplicationController
        skip_before_action :authenticate_user!


        # POST /api/v1/auth/login_password
        def login_password
          user = User.find_by(email: params[:email])

          if user&.valid_password?(params[:password])
            sign_in(user)
            token = current_token

            # Set HttpOnly Cookie
            cookies.signed[:jwt] = {
              value: token,
              httponly: true,
              secure: Rails.env.production?,
              expires: 1.day.from_now
            }

            render json: {
              message: 'Logged in successfully',
              user: UserSerializer.new(user).serializable_hash
            }
          else
            render json: { error: 'Invalid email or password' }, status: :unauthorized
          end
        end

        # POST /api/v1/auth/login
        def create
          user = User.find_by(email: params[:email])
          
          if user
            user.generate_otp!
            # TODO: Send OTP via Mailer
            # UserMailer.with(user: user).otp_email.deliver_later
            
            # For Audit/Dev purposes - returning OTP in response (REMOVE IN PROD)
            render json: { message: 'OTP sent', debug_otp: user.otp_attempt }
          else
            render json: { error: 'User not found' }, status: :not_found
          end
        end

        # POST /api/v1/auth/verify
        def verify
          user = User.find_by(email: params[:email])
          
          if user&.verify_otp(params[:otp])
            # Confirm user if not already confirmed
            user.confirm unless user.confirmed?

            sign_in(user)
            token = current_token
            
            # Set HttpOnly Cookie
            cookies.signed[:jwt] = {
              value: token,
              httponly: true,
              secure: Rails.env.production?,
              expires: 1.day.from_now
            }
            
            render json: { 
              message: 'Logged in successfully', 
              user: UserSerializer.new(user).serializable_hash 
            }
          else
            render json: { error: 'Invalid OTP' }, status: :unauthorized
          end
        end

        private

        def current_token
          request.env['warden-jwt_auth.token']
        end
      end
    end
  end
end
