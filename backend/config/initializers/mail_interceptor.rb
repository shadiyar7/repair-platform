require 'email_interceptor'

if Rails.env.development? || Rails.env.test? || ENV['INTERCEPT_EMAIL'] == 'true'
  ActionMailer::Base.register_interceptor(EmailInterceptor)
  Rails.logger.info "📧 Email Interceptor Registered: All emails will be sent to shadiyar.alakhan@gmail.com"
end
