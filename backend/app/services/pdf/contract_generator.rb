module Pdf
  class ContractGenerator
    include Prawn::View

    def initialize(order)
      @order = order
      @document = Prawn::Document.new(page_size: 'A4', margin: 40)
      
      # Load bundled font for Cyrillic support
      # Load bundled fonts for Cyrillic support (Roboto 2013 version for Prawn compatibility)
      # Load bundled fonts for Cyrillic support (Roboto 2013 version for Prawn compatibility)
      # Note: Using Regular for Bold temporarily to fix missing file 500 error
      font_regular = Rails.root.join('vendor', 'fonts', 'Roboto-Regular.ttf')
      
      begin
        if File.exist?(font_regular)
          size_reg = File.size(font_regular)
          Rails.logger.info "Loading fonts: Regular=#{size_reg}b (Used for Bold too)"
          
          if size_reg > 0
            @document.font_families.update("Roboto" => {
              normal: font_regular.to_s,
              bold: font_regular.to_s,
              italic: font_regular.to_s,
              bold_italic: font_regular.to_s
            })
            @document.font "Roboto"
          else
             Rails.logger.warn "Font file is empty. Fallback to Helvetica."
             @document.font "Helvetica"
          end
        else
          Rails.logger.warn "Font file missing (#{font_regular}). Using Helvetica."
          @document.font "Helvetica"
        end

      rescue => e
        Rails.logger.error "Failed to load Roboto font: #{e.message}. Fallback to Helvetica."
        @document.font "Helvetica"
      end
    end

    def generate
      # Ensure using the custom font if available
      if @document.font_families["Roboto"]
         @document.font "Roboto"
      else
         @document.font "Helvetica"
      end

      # -----------------------------------------------------------------------
      # 1. HEADER
      # -----------------------------------------------------------------------
      text "ДОГОВОР ПОСТАВКИ № #{@order.id}", size: 14, style: :bold, align: :center
      move_down 5
      text "г. Астана                                                                                                          #{Date.today.strftime('%d.%m.%Y')} г.", align: :center
      move_down 20

      # -----------------------------------------------------------------------
      # 2. PREAMBLE
      # -----------------------------------------------------------------------
      
      supplier_text = "ТОО «DYNAMIX»"
      supplier_director = "___________________" # Need to ask user for Director Name if fixed, or leave blank
      buyer_name = @order.company_requisite&.company_name || @order.user.company_name || 'Покупатель'
      buyer_director = @order.company_requisite&.director_name || @order.user.director_name || '___________________'
      buyer_basis = @order.company_requisite&.acting_on_basis || 'Устава'

      preamble = "#{supplier_text}, именуемое в дальнейшем «Поставщик», в лице Директора #{supplier_director}, действующего на основании Устава, с одной стороны, и
#{buyer_name}, именуемое в дальнейшем «Покупатель», в лице Директора #{buyer_director}, действующего на основании #{buyer_basis}, с другой стороны, далее совместно именуемые «Стороны», заключили настоящий Договор о нижеследующем:"

      text preamble, align: :justify, leading: 3
      move_down 15

      # -----------------------------------------------------------------------
      # 3. BODY CLAUSES (Extracted from Template)
      # -----------------------------------------------------------------------
      
      clauses = [
        ["1. Предмет Договора", 
         "1.1. Поставщик обязуется передать в собственность Покупателя, а Покупатель принять и оплатить Товар согласно Спецификации, являющейся неотъемлемой частью настоящего Договора (Приложение №1)."],
        
        ["2. Цена и порядок расчетов", 
         "2.1. Общая сумма Договора определяется согласно Спецификации (Приложение №1).",
         "2.2. Оплата производится Покупателем в размере 100% предоплаты, если иное не оговорено в Спецификации.",
         "2.3. Расчеты производятся в тенге путем перечисления денежных средств на расчетный счет Поставщика."],

        ["3. Сроки и условия поставки",
         "3.1. Поставка Товара осуществляется в сроки, указанные в Спецификации.",
         "3.2. Датой поставки считается дата подписания Сторонами накладной на отпуск запасов на сторону."],

        ["4. Права и обязанности Сторон",
         "4.1. Поставщик обязан передать Товар надлежащего качества и в обусловленный срок.",
         "4.2. Покупатель обязан принять и оплатить Товар в соответствии с условиями Договора."],

        ["5. Качество Товара",
         "5.1. Качество поставляемого Товара должно соответствовать стандартам и техническим условиям завода-изготовителя."],

        ["6. Ответственность Сторон",
         "6.1. За неисполнение или ненадлежащее исполнение обязательств по настоящему Договору Стороны несут ответственность в соответствии с законодательством РК."],

        ["7. Обстоятельства непреодолимой силы",
         "7.1. Стороны освобождаются от ответственности за частичное или полное неисполнение обязательств по настоящему Договору, если это неисполнение явилось следствием обстоятельств непреодолимой силы."],
         
        ["8. Разрешение споров",
         "8.1. Все споры разрешаются путем переговоров.",
         "8.2. В случае невозможности разрешения споров путем переговоров, они подлежат рассмотрению в суде по месту нахождения Поставщика, в соответствии с законодательством РК."],

        ["9. Заключительные положения",
         "9.1. Договор вступает в силу с момента подписания и действует до полного исполнения обязательств.",
         "9.2. Изменения и дополнения к Договору действительны, если они совершены в письменной форме и подписаны Сторонами."]
      ]

      clauses.each do |clause|
        header = clause[0]
        paragraphs = clause[1..-1]
        
        text header, style: :bold
        paragraphs.each do |p|
          text p, align: :justify, leading: 2
        end
        move_down 10
      end

      move_down 20
      
      # -----------------------------------------------------------------------
      # 4. SIGNATURES
      # -----------------------------------------------------------------------
      text "10. Реквизиты и подписи Сторон", style: :bold
      move_down 10

      y_position = cursor
      bounding_box([0, y_position], width: 250) do
        text "ПОСТАВЩИК:", style: :bold
        text "ТОО «DYNAMIX»"
        text "БИН: 123456789012" 
        text "Адрес: г. Астана, ул. Примерная 1"
        text "IBAN: KZ1234567890" 
        text "Банк: Halyk Bank"
        move_down 20
        text "____________________ / Директор"
        text "М.П."
      end

      bounding_box([300, y_position], width: 250) do
        req = @order.company_requisite
        text "ПОКУПАТЕЛЬ:", style: :bold
        text req&.company_name || @order.user.company_name || "________________"
        text "БИН: #{req&.bin || @order.user.bin || '________________'}"
        text "Адрес: #{req&.legal_address || @order.user.legal_address || '________________'}"
        text "IBAN: #{req&.iban || '________________'}"
        text "Банк: #{req&.bank_name || '________________'}"
        move_down 20
        text "____________________ / #{req&.director_name || 'Директор'}"
        text "М.П."
      end

      start_new_page

      # -----------------------------------------------------------------------
      # 5. SPECIFICATION (APPENDIX 1)
      # -----------------------------------------------------------------------
      text "Приложение №1", align: :right
      text "к Договору поставки № #{@order.id} от «#{Date.today.strftime('%d.%m.%Y')}» г.", align: :right
      move_down 10
      text "Спецификация №1", style: :bold, align: :center, size: 14
      move_down 10
      text "г. Астана                                                                                                          #{Date.today.strftime('%d.%m.%Y')} г.", align: :center
      move_down 20

      text "ТОО «DYNAMIX», именуемое в дальнейшем «Поставщик», и #{buyer_name}, именуемое в дальнейшем «Покупатель», согласовали поставку следующего Товара:", align: :justify
      move_down 10

      items = @order.order_items.map.with_index(1) do |item, index|
        # Fallback to product price if item price is missing or zero (matches frontend behavior)
        effective_price = item.price.to_f > 0 ? item.price : (item.product&.price || 0)
        
        [
          index.to_s,
          item.product&.name,
          "шт.",
          item.quantity.to_s,
          ActionController::Base.helpers.number_to_currency(effective_price, unit: "", separator: ",", delimiter: " ", precision: 2).strip,
          ActionController::Base.helpers.number_to_currency(item.quantity * effective_price, unit: "", separator: ",", delimiter: " ", precision: 2).strip
        ]
      end

      items_data = [["№", "Наименование", "Ед. изм.", "Кол-во", "Цена (тг)", "Сумма (тг)"]] + items
      
      table(items_data, header: true, width: 520) do
        row(0).style(font_style: :bold, background_color: "EEEEEE", align: :center)
        cells.borders = [:bottom, :top, :left, :right]
        cells.padding = 5
        column(0).width = 30
        column(2).width = 50
        column(3).width = 50
      end

      move_down 10
      total_sum = @order.total_amount
      text "Общая сумма спецификации: #{ActionController::Base.helpers.number_to_currency(total_sum, unit: "тенге", separator: ",", delimiter: " ", format: "%n %u")}.", style: :bold
      move_down 20
      
      text "1. Поставщик гарантирует, что поставляемый Товар свободен от любых прав третьих лиц."
      text "2. Срок поставки: 7 рабочих дней после получения 100% предоплаты."
      text "3. Настоящая Спецификация является неотъемлемой частью Договора."
      
      move_down 30

      y_pos_spec = cursor
      bounding_box([0, y_pos_spec], width: 250) do
        text "ПОСТАВЩИК:", style: :bold
        text "ТОО «DYNAMIX»"
        move_down 30
        text "____________________ / Директор"
        text "М.П."
      end

      bounding_box([300, y_pos_spec], width: 250) do
        text "ПОКУПАТЕЛЬ:", style: :bold
        text buyer_name
        move_down 30
        text "____________________ / Директор"
        text "М.П."
      end

      render
    end
  end
end
