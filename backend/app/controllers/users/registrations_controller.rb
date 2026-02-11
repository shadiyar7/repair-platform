# frozen_string_literal: true

class Users::RegistrationsController < Devise::RegistrationsController
  # before_action :configure_sign_up_params, only: [:create]
  # before_action :configure_account_update_params, only: [:update]

  # GET /resource/sign_up
  # def new
  #   super
  # end

  # POST /resource
  def create
    build_resource(sign_up_params)

    resource.transaction do
      resource.save
      if resource.persisted?
        if resource.active_for_authentication?
          # This should not happen if confirmable is on and user is not confirmed
          # But if it does, sign them in
          set_flash_message! :notice, :signed_up
          sign_up(resource_name, resource)
          respond_with resource, location: after_sign_up_path_for(resource)
        else
          # User created but needs confirmation.
          # Generate OTP and send email
          resource.generate_otp!
          begin
             UserMailer.with(user: resource).otp_email.deliver_now
          rescue => e
             Rails.logger.error "Failed to send OTP email: #{e.message}"
          end

          render json: {
            status: { code: 200, message: 'Registration successful. Please check your email for OTP.' },
            data: { 
              email: resource.email,
              verification_required: true 
            }
          }
        end
      else
        clean_up_passwords resource
        set_minimum_password_length
        respond_with resource
      end
    end
  end

  respond_to :json

  private

  def respond_with(resource, _opts = {})
    if resource.persisted?
      render json: {
        status: { code: 200, message: 'Signed up successfully.' },
        data: UserSerializer.new(resource).serializable_hash[:data][:attributes]
      }
    else
      # Format errors to match Frontend expectation
      render json: {
        status: { 
          message: "User could not be created successfully.",
          errors: resource.errors.full_messages 
        },
        errors: resource.errors.messages 
      }, status: :unprocessable_entity
    end
  end
end
