Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      resources :orders, only: [:index, :show, :create, :update] do
        member do
          post :checkout
          post :director_sign
          post :sign_contract
          post :pay
          post :find_driver
          post :assign_driver
          post :driver_arrived
          post :start_trip
          post :deliver
          post :complete
          get :download_invoice
          get :download_contract
        end
      end
      resources :products, only: [:index, :show]
      resources :warehouses, only: [:index, :show]
      resources :company_requisites
      get 'orders/by_token/:token', to: 'orders#by_token'

      # Auth
      namespace :auth do
        post 'login', to: 'sessions#create'
        post 'login_password', to: 'sessions#login_password'
        post 'verify', to: 'sessions#verify'
        post 'signup', to: 'registrations#create'
        put 'profile', to: 'registrations#update'
        
        # Password Reset
        post 'password', to: 'passwords#create' # request link
        put 'password', to: 'passwords#update'  # reset with token
        
        # Confirmation
        get 'confirmation', to: 'confirmations#show'
      end
      
      resources :smart_links, param: :token, only: [:show] do
        member do
          post 'location', to: 'smart_links#update_location'
        end
      end

      # Admin Namespace
      namespace :admin do
        resources :warehouses
        resources :products, only: [:index, :create, :update, :destroy] do
          get 'unlinked', on: :collection
        end
      end

      namespace :integrations do
        namespace :one_c do
          get 'stocks', to: 'stocks#index'
          post 'stocks', to: 'stocks#update'
        end
      end
    end
  end
  devise_for :users, path: '', path_names: {
    sign_in: 'login',
    sign_out: 'logout',
    registration: 'signup'
  },
  controllers: {
    sessions: 'users/sessions',
    registrations: 'users/registrations'
  }
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  root to: proc { [200, {}, ['API is online']] }
end
