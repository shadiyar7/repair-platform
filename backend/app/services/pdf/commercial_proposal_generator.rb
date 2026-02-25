module Pdf
  class CommercialProposalGenerator
    include ActionView::Helpers::NumberHelper

    def initialize(products_data)
      @products = products_data
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

      # Header section (Logo and Date)
      logo_path = Rails.root.join("..", "frontend", "public", "logo.jpg")
      if File.exist?(logo_path)
        pdf.image logo_path, width: 150, at: [0, pdf.cursor]
      else
        # Fallback text if logo missing
        pdf.text_box "DYNAMIX", at: [0, pdf.cursor], width: 150, size: 20, style: :bold
      end

      # Date alignment
      pdf.text_box "Дата: #{Date.current.strftime('%d.%m.%Y')}", at: [pdf.bounds.right - 150, pdf.cursor], width: 150, align: :right, size: 11
      
      pdf.move_down 60

      # Recipient
      pdf.text "Первому руководителю", size: 12
      pdf.move_down 20
      pdf.text "____________________ (название компании)", size: 12
      pdf.move_down 40

      # Title
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
        # Ensure we parse numbers properly
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

      pdf.move_down 30

      # Footer text
      pdf.text "Стоимость включает все расходы на доставку до места требования.", size: 10, leading: 2
      pdf.text "Условия оплаты: согласовываются индивидуально (возможна отсрочка платежа).", size: 10, leading: 2

      pdf.move_down 40

      # Fake Signature
      pdf.text "С уважением,", size: 11
      pdf.move_down 5
      pdf.text "Руководитель отдела продаж", size: 11
      pdf.move_down 20
      
      # Pseudo-signature aesthetics
      pdf.font "Arial", style: :bold do
        pdf.text "DYNAMIX by Komandeer Supply", size: 11
      end

      # Pseudo-signature stroke line overlay to look like signature 
      # (Prawn has drawing tools, but let's just make it look formal)
      pdf.stroke_color "0000FF"
      pdf.stroke do
        pdf.move_up 25
        # draw a simple swirly line
        pdf.curve [200, pdf.cursor], [250, pdf.cursor+20], bounds: [[210, pdf.cursor+30], [230, pdf.cursor-10]]
        pdf.move_down 25
      end
      pdf.stroke_color "000000"

      pdf.render
    end
  end
end
