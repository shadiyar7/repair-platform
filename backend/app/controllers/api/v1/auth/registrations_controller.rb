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
            
            # Sync new company profile details down to active requisites
            current_user.company_requisites.where(is_active: true).each do |req|
              if Order.exists?(company_requisite_id: req.id)
                # Soft delete and clone to preserve historical orders
                req.update!(is_active: false)
                
                new_attrs = req.attributes.except('id', 'created_at', 'updated_at').merge(
                  'company_name' => current_user.company_name,
                  'bin' => current_user.bin,
                  'inn' => current_user.inn,
                  'director_name' => current_user.director_name,
                  'acting_on_basis' => current_user.acting_on_basis,
                  'legal_address' => current_user.legal_address,
                  'actual_address' => current_user.actual_address,
                  'is_active' => true
                )
                current_user.company_requisites.create!(new_attrs)
              else
                # Safe to update in place
                req.update!(
                  company_name: current_user.company_name,
                  bin: current_user.bin,
                  inn: current_user.inn,
                  director_name: current_user.director_name,
                  acting_on_basis: current_user.acting_on_basis,
                  legal_address: current_user.legal_address,
                  actual_address: current_user.actual_address
                )
              end
            end

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
          params.permit(:email, :password, :password_confirmation, :role, :company_name, :phone, :director_name, :acting_on_basis, :legal_address, :actual_address, :inn, :bin, :iban, :swift, :first_name, :last_name, :job_title)
        end

        def account_update_params
          params.permit(:company_name, :phone, :director_name, :acting_on_basis, :legal_address, :actual_address, :inn, :bin, :iban, :swift, :first_name, :last_name, :job_title)
        end

        def current_token
          request.env['warden-jwt_auth.token']
        end
      end
    end
  end
end
