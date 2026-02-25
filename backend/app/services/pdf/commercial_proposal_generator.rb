module Pdf
  class CommercialProposalGenerator
    include ActionView::Helpers::NumberHelper

    def initialize(products_data, client_name: nil)
      @products = products_data
      @client_name = client_name || "____________________"
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
      # Move down slightly for the first line of receiver
      receiver_y = pdf.bounds.top - 10
      pdf.text_box "Первому руководителю", 
                   at: [pdf.bounds.right - 250, receiver_y], 
                   width: 250, 
                   align: :right, 
                   size: 11

      pdf.text_box "#{@client_name}", 
                   at: [pdf.bounds.right - 250, receiver_y - 15], 
                   width: 250, 
                   align: :right, 
                   size: 11,
                   style: :bold

      pdf.text_box "(название компании)", 
                   at: [pdf.bounds.right - 250, receiver_y - 30], 
                   width: 250, 
                   align: :right, 
                   size: 9

      # Date alignment (below company name)
      pdf.text_box "Дата: #{Date.current.strftime('%d.%m.%Y')}", 
                   at: [pdf.bounds.right - 250, receiver_y - 50], 
                   width: 250, 
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

      # Total row
      table_data << [
        { content: "Итого:", colspan: 4, align: :right, font_style: :bold },
        { content: number_with_precision(total_sum, precision: 0, delimiter: ' '), align: :right, font_style: :bold }
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
      pdf.text "С уважением,", size: 11
      pdf.move_down 5
      pdf.text "Руководитель отдела продаж", size: 11
      
      # Drawing the "AK" signature
      pdf.stroke_color "1a3b8e" # Dark blue for signature
      pdf.line_width 1.5
      
      # Start drawing relative to current position
      sig_base_x = 220
      sig_base_y = pdf.cursor - 5
      
      pdf.stroke do
        # "A"
        pdf.move_to sig_base_x, sig_base_y
        pdf.line_to sig_base_x + 10, sig_base_y + 25
        pdf.line_to sig_base_x + 20, sig_base_y
        pdf.move_to sig_base_x + 5, sig_base_y + 12
        pdf.line_to sig_base_x + 15, sig_base_y + 12
        
        # "K"
        pdf.move_to sig_base_x + 25, sig_base_y + 25
        pdf.line_to sig_base_x + 25, sig_base_y
        pdf.move_to sig_base_x + 25, sig_base_y + 12
        pdf.line_to sig_base_x + 35, sig_base_y + 25
        pdf.move_to sig_base_x + 25, sig_base_y + 12
        pdf.line_to sig_base_x + 35, sig_base_y
        
        # Flourish (underline/swish)
        pdf.curve [sig_base_x - 10, sig_base_y - 5], [sig_base_x + 50, sig_base_y - 10], 
                  bounds: [[sig_base_x + 10, sig_base_y - 20], [sig_base_x + 30, sig_base_y + 5]]
      end

      pdf.move_down 35
      pdf.font "Arial", style: :bold do
        pdf.text "DYNAMIX by Komandeer Supply", size: 11
      end
      
      pdf.stroke_color "000000"
      pdf.line_width 1

      pdf.render
    end
  end
end
