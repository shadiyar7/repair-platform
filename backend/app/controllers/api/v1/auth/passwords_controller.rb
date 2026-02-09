module Api
  module V1
    module Auth
      class PasswordsController < ApplicationController
        skip_before_action :authenticate_user!

        # POST /api/v1/auth/password
        def create
          if params[:email].blank?
            return render json: { error: 'Email is required' }, status: :unprocessable_entity
          end

          user = User.find_by(email: params[:email])
          
          if user
            user.send_reset_password_instructions
          end

          # Always return success to prevent email enumeration
          render json: { message: 'If this email exists, a password reset link has been sent.' }
        end

        # PUT /api/v1/auth/password
        def update
          user = User.reset_password_by_token(reset_password_params)

          if user.errors.empty?
            render json: { message: 'Password has been reset successfully. Please login.' }
          else
            render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
          end
        end

        private

        def reset_password_params
          params.permit(:reset_password_token, :password, :password_confirmation)
        end
      end
    end
  end
end
