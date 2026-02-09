module Api
  module V1
    module Auth
      class ConfirmationsController < ApplicationController
        skip_before_action :authenticate_user!

        # GET /api/v1/auth/confirmation?confirmation_token=...
        def show
          user = User.confirm_by_token(params[:confirmation_token])

          if user.errors.empty?
            # Issue a token so they are logged in immediately after clicking the link
            sign_in(user)
            token = current_token

             # If using cookies
            cookies.signed[:jwt] = {
              value: token,
              httponly: true,
              secure: Rails.env.production?,
              expires: 1.day.from_now
            }

            # Redirect to frontend "Email Confirmed" page or return JSON
            # Ideally redirect to frontend URL
            redirect_to "#{ENV.fetch('FRONTEND_URL', 'http://localhost:5173')}/auth/confirmed?token=#{token}", allow_other_host: true
          else
             # Redirect to frontend error page
            redirect_to "#{ENV.fetch('FRONTEND_URL', 'http://localhost:5173')}/auth/confirmation_error?error=#{user.errors.full_messages.first}", allow_other_host: true
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
