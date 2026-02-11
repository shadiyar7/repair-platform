class UserMailer < ApplicationMailer
  def otp_email
    @user = params[:user]
    @otp = @user.otp_attempt
    mail(to: @user.email, subject: 'Ваш код подтверждения DYNAMIX')
  end
end
