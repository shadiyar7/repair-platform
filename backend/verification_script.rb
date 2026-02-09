
require 'dotenv/load'
puts "Starting email verification..."
puts "Key present: #{ENV['RESEND_API_KEY'].present?}"

Resend.api_key = ENV['RESEND_API_KEY']

# 1. shadiyar.alakhan@gmail.com (Likely Owner)
begin
  puts "1. Sending to shadiyar.alakhan@gmail.com..."
  Resend::Emails.send({
    from: 'onboarding@resend.dev',
    to: 'shadiyar.alakhan@gmail.com',
    subject: 'Repair Platform: Verification Test',
    html: '<strong>Resend is connected!</strong><p>This email confirms your API key works.</p>'
  })
  puts "✅ Success: Custom email sent to shadiyar.alakhan@gmail.com"
rescue => e
  puts "❌ Failed: shadiyar.alakhan@gmail.com"
  puts "   Error Class: #{e.class}"
  puts "   Error Message: #{e.message}"
  puts "   Error Response: #{e.respond_to?(:response) ? e.response : 'No response'}"
end

# 2. shadiyar@geeko.tech
begin
  puts "\n2. Sending to shadiyar@geeko.tech..."
  Resend::Emails.send({
    from: 'onboarding@resend.dev',
    to: 'shadiyar@geeko.tech', 
    subject: 'Repair Platform: Verification Test',
    html: '<strong>Resend is connected!</strong>'
  })
  puts "✅ Success: Sent to shadiyar@geeko.tech"
rescue => e
  puts "❌ Failed: shadiyar@geeko.tech" 
  puts "   Error: #{e.message}"
end

# 3. shadiyar.botcorp@gmail.com
begin
  puts "\n3. Sending to shadiyar.botcorp@gmail.com..."
  Resend::Emails.send({
    from: 'onboarding@resend.dev',
    to: 'shadiyar.botcorp@gmail.com',
    subject: 'Repair Platform: Verification Test',
    html: '<strong>Resend is connected!</strong>'
  })
  puts "✅ Success: Sent to shadiyar.botcorp@gmail.com"
rescue => e
  puts "❌ Failed: shadiyar.botcorp@gmail.com"
  puts "   Error: #{e.message}"
end
