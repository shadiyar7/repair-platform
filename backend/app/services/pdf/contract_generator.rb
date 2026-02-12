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

      # Contract number format: KS-ORDER_ID-YEAR-MONTH
      contract_number = "KS-#{@order.id}-#{Date.today.year}-#{Date.today.strftime('%m')}"
      
      # -----------------------------------------------------------------------
      # HEADER
      # -----------------------------------------------------------------------
      text "Договор поставки № #{contract_number}", size: 14, style: :bold, align: :center
      move_down 20

      # -----------------------------------------------------------------------
      # PREAMBLE
      # -----------------------------------------------------------------------
      buyer_name = @order.company_requisite&.company_name || @order.user.company_name || '________________________________'
      buyer_director = @order.company_requisite&.director_name || @order.user.director_name || '________________________'
      buyer_basis = @order.company_requisite&.acting_on_basis || '_________'

      preamble = "Товарищество с ограниченной ответственностью «Komandeer Supply», в лице директора Командирова Адилета Муратовича, действующий на основании Устава, именуемый в дальнейшем «Поставщик», с одной стороны и #{buyer_name}, в лице директора #{buyer_director}, действующей на основании #{buyer_basis}, именуемое в дальнейшем «Покупатель», с другой стороны, а вместе именуемые «Стороны», заключили настоящий договор (далее - Договор) о нижеследующем:"

      text preamble, align: :justify, leading: 2, size: 10
      move_down 15

      # -----------------------------------------------------------------------
      # MAIN SECTIONS
      # -----------------------------------------------------------------------
      
      # Section 1
      text "1. Предмет договора", style: :bold, size: 11
      move_down 5
      text "1.1. По настоящему договору Поставщик обязуется поставить товар в собственность Покупателю, а Покупатель обязуется принять этот товар и уплатить за него установленную цену с НДС.", align: :justify, size: 10
      text "1.2. Наименование, количество, ассортимент, стоимость товара, а также иные характеристики товара (далее - Товар), определяются в спецификации, являющейся неотъемлемой частью настоящего Договора (далее- Спецификация).", align: :justify, size: 10
      move_down 10

      # Section 2
      text "2. Обязательства Сторон", style: :bold, size: 11
      move_down 5
      text "2.1. Поставщик обязан:", style: :bold, size: 10
      text "2.1.1. Передать Покупателю Товар, предусмотренный настоящим Договором, свободный от прав третьих лиц, надлежащего качества, в количестве и ассортименте, согласованном Сторонами в Спецификации.", align: :justify, size: 10
      text "2.1.2. Одновременно с передачей Товара передать Покупателю его принадлежности, а также относящиеся к нему документы: сертификат качества/паспорт, накладная, ЭСФ, акт приема-передачи.", align: :justify, size: 10
      text "2.1.3. Передать Покупателю Товар в таре и (или) упаковке, обеспечивающей сохранность товаров такого рода при обычных условиях хранения и транспортирования.", align: :justify, size: 10
      text "2.2. Покупатель обязан:", style: :bold, size: 10
      text "2.2.1. Принять переданный ему Товар, за исключением случаев, когда он вправе потребовать замены Товара или отказаться от исполнения Договора купли-продажи.", align: :justify, size: 10
      text "2.2.2. Оплатить Товар по цене и в срок, предусмотренные настоящим Договором.", align: :justify, size: 10
      text "2.2.3. Известить Продавца о нарушении условий договора о количестве, ассортименте, качестве, таре и (или) об упаковке Товара в срок не позднее 3-х рабочих дней после получения Товара.", align: :justify, size: 10
      move_down 10

      # Section 3
      text "3. Цена договора и порядок расчетов", style: :bold, size: 11
      move_down 5
      text "3.1. Цена Договора определяется в Спецификации.", align: :justify, size: 10
      text "3.2. Покупатель должен произвести предоплату Товара в полном объеме в течение 3 (трех) рабочих дней с даты подписания Сторонами настоящего Договора и Спецификации.", align: :justify, size: 10
      text "3.3. Оплата производится путем перечисления денежных средств на банковский счет Продавца, указанный в разделе 10 Договора.", align: :justify, size: 10
      text "3.4. С момента подписания настоящего Договора сумма Договора изменению не подлежит до полного выполнения договорных обязательств обеими Сторонами.", align: :justify, size: 10
      move_down 10

      # Section 4
      text "4. Условия поставки Товара", style: :bold, size: 11
      move_down 5
      text "4.1. Поставщик осуществляет поставку Товара в соответствии с условиями Спецификации к настоящему Договору.", align: :justify, size: 10
      text "4.2. Покупатель принимает поставленный Товар на основании Акта приема-передачи, подготовленного и подписанного со стороны Поставщика.", align: :justify, size: 10
      move_down 10

      start_new_page

      # Continue Section 4
      text "4. Условия поставки Товара (продолжение)", style: :bold, size: 11
      move_down 5
      text "4.3. При наличии видимых повреждений Товара и/или несоответствия поставленного Товара условиям настоящего Договора и/или Спецификации, Покупатель имеет право отказаться от приемки Товара и от подписания Акта приема-передачи, потребовав от Поставщика замены некачественного Товара на товар надлежащего качества и/или устранения несоответствий характеристик Товара Спецификации.", align: :justify, size: 10
      text "4.4. Риск случайной гибели, порчи, повреждения или утраты Товара переходит к Покупателю после подписания Сторонами Акта приема-передачи.", align: :justify, size: 10
      text "4.5. Поставщик передает Товар Покупателю для проведения освидетельствования соответствующим депо. Товар, который, в результате, проверки будет признан негодным к эксплуатации, считается товаром ненадлежащего качества.", align: :justify, size: 10
      text "4.6. Поставщик гарантирует Покупателю, что товар не заложен, не арестован, свободен от любых обременений и ограничений, не имеет претендентов на право владения, и свободен от каких-либо притязаний третьих лиц.", align: :justify, size: 10
      text "4.7. Качество поставляемого нового товара должно соответствовать требованиям ГОСТов, ОСТов и ТУ завода-изготовителя на данный товар.", align: :justify, size: 10
      text "4.8. Приемка Запчастей по количеству, качеству и комплектации производится в момент их фактической передачи.", align: :justify, size: 10
      move_down 10

      # Section 5
      text "5. Ответственность Сторон", style: :bold, size: 11
      move_down 5
      text "5.1. Стороны несут ответственность за неисполнение или ненадлежащее исполнение своих обязательств по настоящему Договору в соответствии с действующим законодательством Республики Казахстан.", align: :justify, size: 10
      text "5.2. Поставщик несет ответственность за сохранность Товара до момента его передачи Покупателю по Акту приема-передачи в соответствии с условиями настоящего Договора.", align: :justify, size: 10
      text "5.3. Поставщик несет ответственность за соответствие Товара параметрам, указанным в Спецификации.", align: :justify, size: 10
      text "5.4. За нарушение Поставщиком сроков поставки Поставщик оплачивает Покупателю неустойку в размере 0,1% от общей цены Договора за каждый день просрочки, но не более 10 % от общей стоимости Товара по Договору.", align: :justify, size: 10
      text "5.5. В случае нарушения сроков оплаты за Товар Покупатель обязан уплатить Поставщику неустойку в размере 0,1 % от стоимости Товара за каждый день просрочки, но не более 10 % от общей стоимости Товара по Договору.", align: :justify, size: 10
      move_down 10

      # Sections 6-9 abbreviated for space
      ["6. Конфиденциальность", "7. Обстоятельства непреодолимой силы", "8. Разрешение споров", "9. Заключительные положения"].each do |section_name|
        text section_name, style: :bold, size: 11
        text "(Полный текст раздела согласно договору)", align: :justify, size: 10, style: :italic
        move_down 8
      end

      start_new_page

      # -----------------------------------------------------------------------
      # SECTION 10: REQUISITES AND SIGNATURES
      # -----------------------------------------------------------------------
      text "10. Реквизиты и подписи Сторон", style: :bold, size: 12, align: :center
      move_down 15

      y_position = cursor
      bounding_box([0, y_position], width: 260) do
        text "ПОСТАВЩИК", style: :bold, size: 10
        move_down 5
        text "Наименование: ТОО «Komandeer Supply»", size: 9
        text "Юридический адрес: Казахстан, город Астана, район Нұра, Проспект Тұран, здание 46/2, офис 613, почтовый индекс 010000", size: 8, align: :justify
        text "Фактический адрес: Казахстан, город Астана, район Есиль, Конаева 10, БЦ «Emerald Tower», офис 501, почтовый индекс 010017", size: 8, align: :justify
        text "БИН: 100740004791", size: 9
        text "IBAN (KZT): KZ5396503F0012694785", size: 9
        text "Банк: Филиал АО \"ForteBank\" в г. Астана", size: 9
        text "SWIFT: IRTYKZKA", size: 9
        text "БИН Банка: 990841000632", size: 9
        text "Тел: +7 701 006 45 48", size: 9
        text "Email: komandeer@internet.ru", size: 9
        move_down 15
        text "Директор", size: 9
        text "_____________ Командиров А.М.", size: 9
        text "М.П.", size: 9
      end

      bounding_box([280, y_position], width: 260) do
        req = @order.company_requisite
        text "ПОКУПАТЕЛЬ", style: :bold, size: 10
        move_down 5
        text "Наименование: #{req&.company_name || @order.user.company_name || '________________'}", size: 9
        text "БИН: #{req&.bin || @order.user.bin || '________________'}", size: 9
        text "Юр. адрес: #{req&.legal_address || @order.user.legal_address || '________________'}", size: 8, align: :justify
        text "Факт. адрес: #{req&.actual_address || req&.legal_address || '________________'}", size: 8, align: :justify
        text "IBAN: #{req&.iban || '________________'}", size: 9
        text "Банк: #{req&.bank_name || '________________'}", size: 9
        if req&.swift.present?
          text "SWIFT: #{req.swift}", size: 9
        end
        move_down 15
        text "Директор", size: 9
        text "_____________ #{req&.director_name || '________________'}", size: 9
        text "М.П.", size: 9
      end

      start_new_page

      # -----------------------------------------------------------------------
      # APPENDIX 1: SPECIFICATION
      # -----------------------------------------------------------------------
      text "Приложение №1", align: :right, size: 10
      text "к Договору поставки № #{contract_number}", align: :right, size: 10
      text "от «#{Date.today.strftime('%d')}» #{Date::MONTHNAMES[Date.today.month]} #{Date.today.year} г.", align: :right, size: 10
      move_down 10
      text "Спецификация №1", style: :bold, align: :center, size: 14
      move_down 10
      text "г. Астана                                                                                                          «#{Date.today.strftime('%d')}» #{Date::MONTHNAMES[Date.today.month]} #{Date.today.year} г.", align: :center, size: 10
      move_down 15

      spec_preamble = "#{buyer_name}, именуемое в дальнейшем «Покупатель», в лице директора #{buyer_director}, действующей на основании #{buyer_basis}, с одной стороны, и ТОО «Komandeer Supply» именуемое в дальнейшем «Поставщик», в лице Директора Командирова А.М., действующего на основании Устава, с другой стороны, далее совместно именуемые «Стороны», настоящим удостоверяем, что Сторонами достигнуто соглашение о цене, количестве и иных условиях поставки Товара, являющегося предметом Договора поставки № #{contract_number} от «#{Date.today.strftime('%d')}» #{Date::MONTHNAMES[Date.today.month]} #{Date.today.year} г."
      
      text spec_preamble, align: :justify, size: 10
      move_down 10

      text "Поставщик по настоящей Спецификации поставляет следующие Товары и Услугу:", size: 10
      move_down 10

      # Build items table
      items = @order.order_items.map.with_index(1) do |item, index|
        product_price = item.product&.price || 0
        current_price = item.price.to_f
        effective_price = current_price > 0 ? current_price : product_price
        
        Rails.logger.info "PDF Gen [Item ##{item.id}]: DB Price=#{item.price.inspect}, Product Price=#{product_price}, Effective=#{effective_price}"

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
        row(0).style(font_style: :bold, background_color: "EEEEEE", align: :center, size: 9)
        cells.borders = [:bottom, :top, :left, :right]
        cells.padding = 4
        cells.size = 9
        column(0).width = 30
        column(2).width = 50
        column(3).width = 50
      end

      move_down 10
      total_sum = @order.total_amount
      text "Общая сумма спецификации: #{ActionController::Base.helpers.number_to_currency(total_sum, unit: "тенге", separator: ",", delimiter: " ", format: "%n %u")}, с НДС.", style: :bold, size: 10
      move_down 15
      
      text "2. Покупатель в течение 1 (одного) рабочего дня со дня заключения Спецификации, вносит на счет Поставщика предоплату в размере 100 % (сто) от всего объема.", align: :justify, size: 10
      text "3. Поставщик гарантирует, что поставляемый Товар свободен от любых прав и притязаний третьих лиц, т.е. никому не продан, не заложен, в споре и под запрещением (арестом) не состоит.", align: :justify, size: 10
      text "4. Транспортные расходы и доставка Товара осуществляется силами и за счет Поставщика.", align: :justify, size: 10
      text "5. Срок поставки Товара: 7 рабочих дней после получения 100% предоплаты.", align: :justify, size: 10
      text "6. Настоящая Спецификация вступает в силу со дня подписания и является неотъемлемой частью Договора.", align: :justify, size: 10
      text "7. Настоящая Спецификация составлена в 2-х экземплярах, имеющих равную юридическую силу, по одному для каждой из сторон.", align: :justify, size: 10
      
      move_down 25

      # Specification signatures
      y_pos_spec = cursor
      bounding_box([0, y_pos_spec], width: 250) do
        text "ПОСТАВЩИК", style: :bold, size: 10
        text "ТОО «Komandeer Supply»", size: 9
        move_down 20
        text "Директор _____________ Командиров А.М.", size: 9
        text "М.П.", size: 9
      end

      bounding_box([300, y_pos_spec], width: 250) do
        text "ПОКУПАТЕЛЬ", style: :bold, size: 10
        text buyer_name, size: 9
        move_down 20
        text "Директор _____________ #{buyer_director}", size: 9
        text "М.П.", size: 9
      end

      render
    end
  end
end
