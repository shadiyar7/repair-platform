class VerificationMailer < ApplicationMailer
  default from: 'noreply@loopa.kz'

  def send_otp(user)
    @user = user
    @otp_code = user.otp_attempt
    
    mail(
      to: @user.email, 
      subject: 'Код подтверждения | Dynamix'
    )
  end
end
