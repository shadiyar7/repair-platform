module IDocs
  class ContractSigner
    def initialize(order)
      @order = order
    end

    def call
      # Simulate API delay
      sleep 2.0

      # Simulate signing process
      @order.update(status: 'pending_payment')

      {
        success: true,
        contract_id: "CTR-#{Time.now.year}-#{@order.id}",
        signed_at: Time.now,
        pdf_url: "http://localhost:3000/api/v1/orders/#{@order.id}/contract.pdf"
      }
    end

    def generate_contract_pdf
      Prawn::Document.new(page_size: 'A4', margin: [50, 50, 50, 50]) do |pdf|
        # Load fonts for Cyrillic support
        pdf.font_families.update("Arial" => {
          normal: Rails.root.join("app/assets/fonts/Arial.ttf").to_s,
          bold: Rails.root.join("app/assets/fonts/Arial Bold.ttf").to_s
        })
        pdf.font "Arial"

        # Header
        pdf.text "ДОГОВОР ПОСТАВКИ № CTR-#{Time.now.year}-#{@order.id}", size: 16, style: :bold, align: :center
        pdf.move_down 10
        pdf.text "г. Алматы", align: :left
        pdf.move_up 12
        pdf.text "«#{Date.today.day}» #{russian_month(Date.today.month)} #{Date.today.year} г.", align: :right
        pdf.move_down 20

        # Parties
        pdf.text "ТОО «Komandeer Supply»", style: :bold
        pdf.text "в лице Директора Командирова А.М., действующего на основании Устава, именуемое в дальнейшем «Поставщик», с одной стороны, и"
        pdf.move_down 10
        requisite = @order.company_requisite || @order.user
        pdf.text "«#{requisite.company_name}»", style: :bold
        pdf.text "в лице Директора #{requisite.director_name}, действующего на основании #{requisite.acting_on_basis}, именуемое в дальнейшем «Покупатель», с другой стороны, совместно именуемые «Стороны», заключили настоящий Договор о нижеследующем:"
        
        pdf.move_down 20
        pdf.text "1. ПРЕДМЕТ ДОГОВОРА", style: :bold
        pdf.text "1.1. Поставщик обязуется поставить, а Покупатель принять и оплатить Товар (Запасные части для железнодорожного транспорта) в количестве и ассортименте согласно Спецификации (Приложение №1), являющейся неотъемлемой частью настоящего Договора."
        
        pdf.move_down 15
        pdf.text "2. СТОИМОСТЬ И ПОРЯДОК РАСЧЕТОВ", style: :bold
        pdf.text "2.1. Общая сумма Договора составляет #{@order.total_amount} тенге."
        pdf.text "2.2. Покупатель обязуется произвести 100% предоплату в течение 3 (трех) банковских дней с момента подписания настоящего Договора."

        pdf.move_down 30
        pdf.text "ПРИЛОЖЕНИЕ №1", style: :bold, align: :right
        pdf.text "к Договору № CTR-#{Time.now.year}-#{@order.id}", align: :right
        pdf.move_down 10
        pdf.text "СПЕЦИФИКАЦИЯ ТОВАРА", style: :bold, align: :center
        pdf.move_down 10

        # Manual Table
        pdf.stroke_horizontal_rule
        pdf.move_down 5
        pdf.text "№ | Наименование | Кол-во | Цена (ТГ) | Сумма (ТГ)", style: :bold
        pdf.stroke_horizontal_rule
        pdf.move_down 5

        @order.order_items.each_with_index do |item, index|
          product_name = item.product&.name || "Товар"
          price = item.price || 0
          quantity = item.quantity || 0
          total = price * quantity
          pdf.text "#{index + 1} | #{product_name} | #{quantity} | #{price} | #{total}"
          pdf.move_down 2
        end

        pdf.move_down 10
        pdf.stroke_horizontal_rule
        pdf.text "ИТОГО: #{@order.total_amount} KZT", style: :bold, align: :right

        pdf.move_down 40
        
        # Signatures
        pdf.column_box([0, pdf.cursor], columns: 2, width: pdf.bounds.width) do
          pdf.text "ПОСТАВЩИК:", style: :bold
          pdf.text "ТОО «Komandeer Supply»"
          pdf.text "БИН: 100740004791"
          pdf.text "ИИК: KZ5396503F0012694785"
          pdf.text "Банк: Филиал АО \"ForteBank\" в г. Астана"
          pdf.text "Адрес: г. Астана, Конаева 10, БЦ «Emerald Tower», офис 501"
          pdf.move_down 20
          pdf.text "________________ / Командиров А.М."
          
          pdf.bounds.move_past_bottom
          
          pdf.text "ПОКУПАТЕЛЬ:", style: :bold
          requisite = @order.company_requisite || @order.user
          pdf.text "#{requisite.company_name}"
          pdf.text "БИН/ИИН: #{requisite.try(:bin) || requisite.try(:inn)}"
          pdf.text "ИИК: #{requisite.try(:iban) || 'Не указан'}"
          pdf.text "Банк: #{requisite.try(:swift) || 'Не указан'}"
          pdf.text "Адрес: #{requisite.try(:legal_address) || requisite.try(:actual_address) || 'Не указан'}"
          pdf.move_down 20
          pdf.text "________________ / #{requisite.director_name}"
        end

        pdf.move_down 50
        pdf.text "ПОДПИСАНО ЭЛЕКТРОННОЙ ПОДПИСЬЮ В СИСТЕМЕ RE:PAIR", align: :center, color: "0000FF", size: 10
      end.render
    end

    private

    def russian_month(month)
      %w[января февраля марта апреля мая июня июля августа сентября октября ноября декабря][month - 1]
    end
  end
end
