class ApplicationController < ActionController::API
  include Pundit::Authorization
  include ActionController::Cookies

  before_action :configure_permitted_parameters, if: :devise_controller?

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: %i[role company_name inn phone director_name acting_on_basis legal_address actual_address bin iban swift])
    devise_parameter_sanitizer.permit(:account_update, keys: %i[role company_name inn phone director_name acting_on_basis legal_address actual_address bin iban swift])
  end
end
