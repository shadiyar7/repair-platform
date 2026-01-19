module OneC
  class InvoiceGenerator
    def initialize(order)
      @order = order
    end

    def call
      # Simulate API delay
      sleep 1.5

      @order.update(status: 'pending_payment')
      
      {
        success: true,
        invoice_number: "INV-#{Time.now.year}-#{@order.id.to_s.rjust(6, '0')}",
        amount: @order.total_amount,
        pdf_url: "http://localhost:3000/api/v1/orders/#{@order.id}/invoice.pdf"
      }
    end

    private

    def generate_pdf
      Prawn::Document.new(page_size: 'A4', margin: [50, 50, 50, 50]) do |pdf|
        # Load fonts for Cyrillic support
        pdf.font_families.update("Arial" => {
          normal: Rails.root.join("app/assets/fonts/Arial.ttf").to_s,
          bold: Rails.root.join("app/assets/fonts/Arial Bold.ttf").to_s
        })
        pdf.font "Arial"

        # Header
        pdf.text "СЧЕТ НА ОПЛАТУ № INV-#{Time.now.year}-#{@order.id}", size: 18, style: :bold, align: :center
        pdf.move_down 10
        pdf.text "Дата: #{Date.today.strftime('%d.%m.%Y')}", align: :right
        pdf.move_down 20

        # Supplier
        pdf.text "ПОСТАВЩИК:", style: :bold
        pdf.text "ТОО «Comander Sup»"
        pdf.text "БИН: 123456789012"
        pdf.text "Адрес: г. Алматы, пр. Аль-Фараби, 77/7"
        pdf.text "ИИК: KZ123456789012345678 в АО «Kaspi Bank»"
        pdf.move_down 15

        # Customer
        requisite = @order.company_requisite || @order.user
        pdf.text "ПОКУПАТЕЛЬ:", style: :bold
        pdf.text "#{requisite.company_name}"
        pdf.text "БИН: #{requisite.bin}"
        pdf.text "Адрес: #{requisite.legal_address}"
        pdf.move_down 20

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
        pdf.text "ИТОГО К ОПЛАТЕ: #{@order.total_amount} KZT", style: :bold, align: :right

        pdf.move_down 40
        pdf.text "Руководитель: ________________ / Сулейменов К.А.", size: 10
        pdf.move_down 10
        pdf.text "Бухгалтер: ________________ / Иванова Т.В.", size: 10
        
        pdf.move_down 30
        pdf.text "М.П.", align: :center, size: 12
      end.render
    end
  end
end
