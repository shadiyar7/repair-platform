module Api
  module V1
    module Admin
      class UsersController < ApplicationController
        before_action :authenticate_user!
        before_action :ensure_admin!

        def index
          # List only staff users (not clients, or all if preferred, but requirements say "staff")
          users = User.where.not(role: 'client')
          render json: UserSerializer.new(users).serializable_hash
        end

        def create
          user = User.new(user_params)
          user.password = params[:user][:password]
          user.password_confirmation = params[:user][:password]
          user.email_confirmed = true # Admins create pre-confirmed users
          user.confirmed_at = Time.now # Skip Devise confirmation for staff

          if user.save
            render json: UserSerializer.new(user).serializable_hash, status: :created
          else
            render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
          end
        end

        def update
          user = User.find(params[:id])
          
          # Prevent editing self role/status if safer, but for now allow full edit
          if user.update(user_params)
            render json: UserSerializer.new(user).serializable_hash
          else
            render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
          end
        end

        def destroy
          user = User.find(params[:id])
          if user.destroy
            head :no_content
          else
            render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
          end
        end

        private

        def ensure_admin!
          unless current_user&.admin?
            render json: { error: 'Access denied' }, status: :forbidden
          end
        end

        def user_params
          params.require(:user).permit(:email, :phone, :role, :job_title, :password) # Password optional in update
        end
      end
    end
  end
end
