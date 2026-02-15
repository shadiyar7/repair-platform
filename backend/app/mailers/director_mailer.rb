class DirectorMailer < ApplicationMailer
  default from: 'notifications@dynamix.kz'

  def signature_request(order)
    @order = order
    @director_email = 'director@dynamix.kz' # In real app, find User with role 'director'
    
    # Try to find actual director user
    director = User.find_by(role: 'director')
    @director_email = director.email if director

    mail(to: @director_email, subject: "Требуется подпись: Заказ ##{@order.id}")
  end
end
