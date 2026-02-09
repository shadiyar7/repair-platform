class EmailInterceptor
  def self.delivering_email(message)
    # Store original recipient for debugging/visibility
    original_to = message.to.join(', ')
    
    # Modify Subject to indicate interception
    message.subject = "[TESTING - To: #{original_to}] #{message.subject}"
    
    # Redirect to safe admin email
    message.to = ['shadiyar.alakhan@gmail.com']
    
    # Optional: Clear CC/BCC to prevent leaks
    message.cc = nil
    message.bcc = nil
  end
end
