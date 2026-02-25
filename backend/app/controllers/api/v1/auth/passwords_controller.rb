module Api
  module V1
    module Auth
      class PasswordsController < ApplicationController
        skip_before_action :authenticate_user!

        # POST /api/v1/auth/password
        # Request OTP for password reset
        def create
          if params[:email].blank?
            return render json: { error: 'Email не указан' }, status: :unprocessable_entity
          end

          user = User.find_by(email: params[:email].strip.downcase)
          
          if user
            # Reuse the same OTP mechanism as in registration
            user.generate_otp!
            begin
              UserMailer.with(user: user).password_reset_otp_email.deliver_now
            rescue => e
              Rails.logger.error "Failed to send password reset OTP: #{e.message}"
            end
          end

          # Always return success to prevent email enumeration
          render json: { message: 'Если такой email существует, на него отправлен код восстановления.' }
        end

        # PUT /api/v1/auth/password
        # Verify OTP code and set new password
        def update
          email = params[:email]&.strip&.downcase
          otp = params[:otp]
          new_password = params[:password]
          password_confirmation = params[:password_confirmation]

          if email.blank? || otp.blank? || new_password.blank?
            return render json: { error: 'Заполните все поля' }, status: :unprocessable_entity
          end

          user = User.find_by(email: email)

          if user.nil? || !user.verify_otp(otp)
            return render json: { error: 'Неверный код или срок действия истёк' }, status: :unprocessable_entity
          end

          if new_password != password_confirmation
            return render json: { error: 'Пароли не совпадают' }, status: :unprocessable_entity
          end

          if user.update(password: new_password, password_confirmation: password_confirmation)
            # Invalidate OTP after successful reset
            user.update_columns(otp_attempt: nil, otp_sent_at: nil)
            render json: { message: 'Пароль успешно изменён. Войдите с новым паролем.' }
          else
            render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
          end
        end
      end
    end
  end
end
