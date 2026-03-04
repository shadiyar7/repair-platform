module Pdf
  class CommercialProposalGenerator
    include ActionView::Helpers::NumberHelper

    def initialize(products_data, client_name: nil, director_name: nil)
      @products = products_data
      @client_name = client_name || "____________________"
      @director_name = director_name
    end

    def generate
      # Initialize Prawn Document
      pdf = Prawn::Document.new(page_size: 'A4', margin: [40, 40, 40, 40])
      
      # Setup Fonts for Cyrillic support
      pdf.font_families.update(
        "Arial" => {
          normal: Rails.root.join("app", "assets", "fonts", "Arial.ttf"),
          bold: Rails.root.join("app", "assets", "fonts", "Arial Bold.ttf")
        }
      )
      pdf.font "Arial"

      # --- Header section ---
      logo_path = Rails.root.join("..", "frontend", "public", "logo.jpg")
      if File.exist?(logo_path)
        # Place logo at top left, but track height to avoid overlap
        pdf.image logo_path, width: 140, at: [0, pdf.bounds.top]
      else
        pdf.text_box "DYNAMIX", at: [0, pdf.bounds.top], width: 150, size: 20, style: :bold
      end

      # Recipient block on the right
      receiver_y = pdf.bounds.top - 10
      
      # Recipient title
      pdf.text_box "Первому руководителю", 
                   at: [pdf.bounds.right - 280, receiver_y], 
                   width: 280, 
                   align: :right, 
                   size: 11

      # Recipient Name (Director)
      director_display = @director_name.present? ? "г-ну #{@director_name}" : "____________________"
      pdf.text_box director_display, 
                   at: [pdf.bounds.right - 280, receiver_y - 15], 
                   width: 280, 
                   align: :right, 
                   size: 11

      # Client Company Name
      pdf.text_box "#{@client_name}", 
                   at: [pdf.bounds.right - 280, receiver_y - 30], 
                   width: 280, 
                   align: :right, 
                   size: 11,
                   style: :bold

      pdf.text_box "(название компании)", 
                   at: [pdf.bounds.right - 280, receiver_y - 45], 
                   width: 280, 
                   align: :right, 
                   size: 8

      # Date alignment (below company name)
      pdf.text_box "Дата: #{Date.current.strftime('%d.%m.%Y')}", 
                   at: [pdf.bounds.right - 280, receiver_y - 65], 
                   width: 280, 
                   align: :right, 
                   size: 10
      
      # We need to manually set cursor below the header elements
      pdf.move_cursor_to pdf.bounds.top - 100

      # Title
      pdf.move_down 20
      pdf.text "Коммерческое предложение", size: 16, style: :bold, align: :center
      pdf.move_down 20

      # Intro text
      intro_text = "DYNAMIX by Komandeer Supply — это цифровой сервис закупки колесных пар и запчастей для ТОР с доставкой до точки отцепки за 2 дня."
      pdf.text intro_text, size: 11, leading: 2
      pdf.move_down 15

      pdf.text "Преимущества для вас:", style: :bold, size: 11
      pdf.move_down 5

      bullets = [
        "Сокращение простоя до -50% и снижение затрат до 100 млн в год",
        "Выпуск вагона без ожидания длинных поставок",
        "Фиксированная цена без торгов и посредников",
        "Полный контроль сделки в одном окне",
        "Выкуп забракованных колесных пар",
        "Легитимные запасные части с полным пакетом документов"
      ]

      bullets.each do |bullet|
        pdf.text "• #{bullet}", size: 11, leading: 2, indent_paragraphs: 10
      end

      pdf.move_down 15
      pdf.text "По вашей заявке предлагаем следующее:", size: 11
      pdf.move_down 10

      # Table Data
      table_data = [
        [
          { content: "№", font_style: :bold, align: :center },
          { content: "Наименование", font_style: :bold, align: :center },
          { content: "Кол-во", font_style: :bold, align: :center },
          { content: "Цена без НДС, ₸", font_style: :bold, align: :center },
          { content: "Сумма без НДС, ₸", font_style: :bold, align: :center }
        ]
      ]

      total_sum = 0
      @products.each_with_index do |item, index|
        price = item[:price].to_f
        quantity = item[:quantity].to_f
        total = price * quantity
        total_sum += total

        table_data << [
          { content: (index + 1).to_s, align: :center },
          { content: item[:name].to_s },
          { content: number_with_precision(quantity, precision: 0, delimiter: ' '), align: :center },
          { content: number_with_precision(price, precision: 0, delimiter: ' '), align: :right },
          { content: number_with_precision(total, precision: 0, delimiter: ' '), align: :right }
        ]
      end

      # Calculation Breakdowns
      discount_percent = GlobalDiscount.current&.active ? GlobalDiscount.current.percent.to_f : 0.0
      discount_amount = total_sum * (discount_percent / 100.0)
      discounted_base = total_sum - discount_amount
      vat_amount = discounted_base * 0.16
      final_total = discounted_base + vat_amount

      # Total rows
      table_data << [
        { content: "Итого (без НДС):", colspan: 4, align: :right, font_style: :bold },
        { content: number_with_precision(total_sum, precision: 0, delimiter: ' '), align: :right, font_style: :bold }
      ]

      if discount_amount > 0
        table_data << [
          { content: "Скидка (#{discount_percent.to_i}%):", colspan: 4, align: :right, font_style: :normal },
          { content: "-#{number_with_precision(discount_amount, precision: 0, delimiter: ' ')}", align: :right, font_style: :bold, text_color: "228B22" }
        ]
      end

      table_data << [
        { content: "НДС (16%):", colspan: 4, align: :right, font_style: :bold },
        { content: number_with_precision(vat_amount, precision: 0, delimiter: ' '), align: :right, font_style: :bold }
      ]

      table_data << [
        { content: "Итого к оплате (с НДС):", colspan: 4, align: :right, font_style: :bold },
        { content: number_with_precision(final_total, precision: 0, delimiter: ' '), align: :right, font_style: :bold, text_color: "FF0000" }
      ]

      # Draw table
      pdf.table(table_data, width: pdf.bounds.width, header: true) do |t|
        t.cells.padding = [5, 5, 5, 5]
        t.cells.size = 10
        t.row(0).background_color = "F0F0F0"
        t.column(0).width = 30
        t.column(2).width = 60
        t.column(3).width = 100
        t.column(4).width = 100
      end

      pdf.move_down 20
      pdf.text "Стоимость включает все расходы на доставку до места требования.", size: 9, leading: 2
      pdf.text "Условия оплаты: согласовываются индивидуально (возможна отсрочка платежа).", size: 9, leading: 2

      pdf.move_down 30

      # --- Signature Section ---
      y_position = pdf.cursor

      pdf.bounding_box([0, y_position], width: 300) do
        pdf.text "С уважением,", size: 11
        pdf.move_down 5
        pdf.text "Адилет Командиров", size: 11, style: :bold
        pdf.text "Директор ТОО “Komandeer Supply”", size: 11
        
        pdf.move_down 20
        pdf.font "Arial", style: :bold do
          pdf.text "DYNAMIX by Komandeer Supply", size: 11
        end
      end

      # Add signature and stamp images to the right
      signature_path = Rails.root.join("app/assets/images/pdf/signature.jpg")
      stamp_path = Rails.root.join("app/assets/images/pdf/stamp.jpg")

      if File.exist?(signature_path)
        pdf.image signature_path, at: [280, y_position + 15], width: 120
      end

      if File.exist?(stamp_path)
        pdf.image stamp_path, at: [350, y_position + 30], width: 140
      end

      pdf.render
    end
  end
end
