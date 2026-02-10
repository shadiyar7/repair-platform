# verify_email_sending.rb
require 'ostruct'

puts "--- Configuring SMTP for Local Test ---"
# Force SMTP settings for this script execution to verify credentials
ActionMailer::Base.delivery_method = :smtp
ActionMailer::Base.smtp_settings = {
  address:              'smtp.gmail.com',
  port:                 587,
  domain:               'loopa.kz',
  user_name:            ENV['SMTP_USERNAME'],
  password:             ENV['SMTP_PASSWORD'],
  authentication:       'plain',
  enable_starttls_auto: true
}
ActionMailer::Base.perform_deliveries = true
ActionMailer::Base.raise_delivery_errors = true

# CRITICAL: Unregister the development interceptor to test real delivery
begin
  ActionMailer::Base.unregister_interceptor(EmailInterceptor)
  puts "🚫 Interceptor unregistered for this test."
rescue => e
  puts "⚠️ Could not unregister interceptor: #{e.message}"
end

recipients = [
  "shadiyar.alakhan@gmail.com", 
  "shadiyar.botcorp@gmail.com", 
  "shadiyar@geeko.tech"
]

puts "--- Sending Emails ---"

recipients.each do |email|
  puts "📤 Sending to #{email}..."
  
  # Mock user-like object to satisfy Mailer contract
  user = OpenStruct.new(
    email: email,
    otp_attempt: rand(100000..999999).to_s
  )
  
  begin
    # Using deliver_now to see immediate errors
    VerificationMailer.send_otp(user).deliver_now
    puts "✅ Sent successfully to #{email}"
  rescue => e
    puts "❌ Failed to send to #{email}"
    puts "   Error: #{e.message}"
  end
end

puts "--- Done ---"
