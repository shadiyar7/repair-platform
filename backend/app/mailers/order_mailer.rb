class OrderMailer < ApplicationMailer
  default from: 'DYNAMIX <noreply@komandeer.kz>' # Adjust as per verified Resend domain

  before_action :set_recipients

  # Шаг 1: Заказ создается
  def order_created
    @order = params[:order]
    
    mail(
      to: determine_to(['komandeer@internet.ru', 'sales2@komandeer.kz']),
      cc: determine_cc,
      subject: "[Новый заказ] Заказ №#{@order.id} принят в обработку"
    )
  end

  # Шаг 2: Нужно подписать договор (с нашей стороны)
  def pending_director_signature
    @order = params[:order]
    
    mail(
      to: determine_to(['komandeer@internet.ru', 'adiletmt@gmail.com', 'sales2@komandeer.kz']),
      cc: determine_cc,
      subject: "[Требуется подпись] Подпишите договор по заказу №#{@order.id}"
    )
  end

  # Шаг 3: Договор подписан со стороны клиента
  def client_signed
    @order = params[:order]
    
    mail(
      to: determine_to(['komandeer@internet.ru', 'sales2@komandeer.kz']),
      cc: determine_cc,
      subject: "[Договор подписан] Клиент подписал договор по заказу №#{@order.id}"
    )
  end

  # Шаг 4: Клиент загрузил платежку (чек)
  def receipt_uploaded
    @order = params[:order]
    
    mail(
      to: determine_to(['aidana_komandeer@mail.ru', 'sales2@komandeer.kz']),
      cc: determine_cc,
      subject: "[Проверка оплаты] Загружена платежка по заказу №#{@order.id}"
    )
  end

  # Шаг 5: Бухгалтер подтвердил оплату (Поиск водителя)
  def payment_confirmed
    @order = params[:order]
    
    mail(
      to: determine_to(['komandeer@internet.ru', 'sales2@komandeer.kz']),
      cc: determine_cc,
      subject: "[Оплата получена] Заказ №#{@order.id} передан логистам"
    )
  end

  # Шаг 6: Обновления статусов водителя
  def driver_status_update
    @order = params[:order]
    @status_text = params[:status_text] || "Статус доставки обновлен"
    
    mail(
      to: determine_to(['komandeer@internet.ru', 'sales2@komandeer.kz']),
      cc: determine_cc,
      subject: "[Статус доставки] #{@status_text} - Заказ №#{@order.id}"
    )
  end

  # Шаг 7: Водитель доставил заказ
  def order_delivered
    @order = params[:order]
    
    mail(
      to: determine_to(['komandeer@internet.ru', 'sales2@komandeer.kz', 'aidana_komandeer@mail.ru', 'n.ayazbayeva@komandeer.kz']),
      cc: determine_cc,
      subject: "[Успешно доставлен] Заказ №#{@order.id} закрыт"
    )
  end

  private

  def set_recipients
    @is_test = params[:is_test].present?
  end

  def determine_to(default_recipients)
    if @is_test
      ['shadiyar.alakhan@gmail.com']
    else
      default_recipients
    end
  end

  def determine_cc
    if @is_test
      nil
    else
      ['shadiyar.alakhan@gmail.com']
    end
  end
end
