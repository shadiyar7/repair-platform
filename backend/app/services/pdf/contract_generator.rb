module Pdf
  class ContractGenerator
    include Prawn::View

    def initialize(order)
      @order = order
      @document = Prawn::Document.new(page_size: 'A4', margin: 40)
      @indent = "     " # ~5 spaces for iDocs QR code safety
      
      # Load font
      font_regular = Rails.root.join('vendor', 'fonts', 'Roboto-Regular.ttf')
      begin
        if File.exist?(font_regular)
          @document.font_families.update("Roboto" => {
            normal: font_regular.to_s,
            bold: font_regular.to_s,
            italic: font_regular.to_s,
            bold_italic: font_regular.to_s
          })
          @document.font "Roboto"
        end
      rescue => e
        Rails.logger.error "Font Load Error: #{e.message}"
      end
    end

    def generate
      months_ru = {
        1 => 'января', 2 => 'февраля', 3 => 'марта', 4 => 'апреля',
        5 => 'мая', 6 => 'июня', 7 => 'июля', 8 => 'августа',
        9 => 'сентября', 10 => 'октября', 11 => 'ноября', 12 => 'декабря'
      }
      day = Date.today.strftime('%d')
      month = months_ru[Date.today.month]
      year = Date.today.year
      number = "KS-#{@order.id}-#{year}-#{Date.today.strftime('%m')}"

      if @order.is_existing_client?
        generate_recurrent_contract(number, day, month, year)
      else
        generate_full_contract(number, day, month, year)
      end

      render
    end

    private

    def generate_recurrent_contract(number, day, month, year)
      # Requisites first or just appendix?
      # User: "Generate the contract using the specification block ... and append their requisites at the bottom."
      buyer_name = (@order.company_requisite&.company_name&.gsub(/\(Main\)/, '')&.strip || @order.user.company_name&.gsub(/\(Main\)/, '')&.strip || '________________________________')
      buyer_director = @order.company_requisite&.director_name || @order.user.director_name || '________________________'
      buyer_basis = @order.company_requisite&.acting_on_basis.presence || 'Устава'
      
      render_appendix_content(number, day, month, year, buyer_name, buyer_director, buyer_basis)
    end

    def generate_full_contract(number, day, month, year)
      buyer_name = (@order.company_requisite&.company_name&.gsub(/\(Main\)/, '')&.strip || @order.user.company_name&.gsub(/\(Main\)/, '')&.strip || '________________________________')
      buyer_director = @order.company_requisite&.director_name || @order.user.director_name || '________________________'
      buyer_basis = @order.company_requisite&.acting_on_basis.presence || 'Устава'

      i_text "Договор поставки № #{number}", size: 14, style: :bold, align: :center
      move_down 20

      preamble = "Товарищество с ограниченной ответственностью «Komandeer Supply», в лице директора Командирова Адилета Муратовича, действующий на основании Устава, именуемый в дальнейшем «Поставщик», с одной стороны и #{buyer_name}, в лице директора #{buyer_director}, действующего на основании #{buyer_basis}, именуемое в дальнейшем «Покупатель», с другой стороны, а вместе именуемые «Стороны», заключили настоящий договор (далее - Договор) о нижеследующем:"
      i_text preamble, align: :justify, size: 10
      move_down 15

      i_text "1. Предмет договора", style: :bold, size: 11
      i_text "1.1. По настоящему договору Поставщик обязуется поставить товар в собственность Покупателю, а Покупатель обязуется принять этот товар и уплатить за него установленную цену с НДС.", align: :justify, size: 10
      i_text "1.2. Наименование, количество, ассортимент, стоимость товара, а также иные характеристики товара (далее - Товар), определяются в спецификации, являющейся неотъемлемой частью настоящего Договора (далее- Спецификация).", align: :justify, size: 10
      i_text "1.3. В случае противоречия условий настоящего Договора и Спецификации приоритет имеют условия Спецификации.", align: :justify, size: 10
      move_down 10

      i_text "2. Обязательства Сторон", style: :bold, size: 11
      i_text "2.1. Поставщик обязан:", style: :bold, size: 10
      i_text "2.1.1. Передать Покупателю Товар, предусмотренный настоящим Договором, свободный от прав третьих лиц, надлежащего качества, в количестве и ассортименте, согласованном Сторонами в Спецификации.", align: :justify, size: 10
      i_text "2.1.2. Одновременно с передачей Товара передать Покупателю его принадлежности, а также относящиеся к нему документы: сертификат качества/паспорт, накладная, ЭСФ, акт приема-передачи.", align: :justify, size: 10
      i_text "2.1.3. Передать Покупателю Товар в таре и (или) упаковке, обеспечивающей сохранность товаров такого рода при обычных условиях хранения и транспортирования.", align: :justify, size: 10
      i_text "2.2. Покупатель обязан:", style: :bold, size: 10
      i_text "2.2.1. Принять переданный ему Товар, за исключением случаев, когда он вправе потребовать замены Товара или отказаться от исполнения Договора купли-продажи.", align: :justify, size: 10
      i_text "2.2.2. Оплатить Товар по цене и в срок, предусмотренные настоящим Договором.", align: :justify, size: 10
      i_text "2.2.3. Известить Продавца о нарушении условий договора о количестве, ассортименте, качестве, таре и (или) об упаковке Товара в срок не позднее 3-х рабочих дней после получения Товара.", align: :justify, size: 10
      move_down 10

      i_text "3. Цена договора и порядок расчетов", style: :bold, size: 11
      i_text "3.1. Цена Договора определяется в Спецификации.", align: :justify, size: 10
      i_text "3.2. Покупатель должен произвести предоплату Товара в полном объеме в течение 3 (трех) рабочих дней с даты подписания Сторонами настоящего Договора и Спецификации.", align: :justify, size: 10
      i_text "3.3. Оплата производится путем перечисления денежных средств на банковский счет Продавца, указанный в разделе 10 Договора.", align: :justify, size: 10
      i_text "3.4. С момента подписания настоящего Договора сумма Договора изменению не подлежит до полного выполнения договорных обязательств обеими Сторонами.", align: :justify, size: 10
      move_down 10

      start_new_page
      i_text "4. Условия поставки Товара", style: :bold, size: 11
      i_text "4.1. Поставщик осуществляет поставку Товара в соответствии с условиями Спецификации к настоящему Договору.", align: :justify, size: 10
      i_text "4.2. Покупатель принимает поставленный Товар на основании Акта приема-передачи, подписанного уполномоченными представителями обеих Сторон.", align: :justify, size: 10
      i_text "4.3. При наличии видимых повреждений Товара и/или несоответствия поставленного Товара условиям настоящего Договора и/или Спецификации, Покупатель имеет право отказаться от приемки Товара и от подписания Акта приема-передачи, потребовав от Поставщика замены некачественного Товара на товар надлежащего качества и/или устранения несоответствий характеристик Товара Спецификации.", align: :justify, size: 10
      i_text "4.4. Риск случайной гибели, порчи, повреждения или утраты Товара переходит к Покупателю после подписания Сторонами Акта приема-передачи.", align: :justify, size: 10
      i_text "4.5. Поставщик передает Товар Покупателю для проведения освидетельствования соответствующим депо. В случае признания Товара негодным к эксплуатации Стороны составляют соответствующий акт. Поставщик обязан в течение согласованного Сторонами срока устранить выявленные недостатки либо заменить Товар на товар надлежащего качества. После устранения недостатков Товар повторно предъявляется к приемке и оформляется Актом приема-передачи.", align: :justify, size: 10
      i_text "4.6. Поставщик гарантирует Покупателю, что товар не заложен, не арестован, свободен от любых обременений и ограничений, не имеет претендентов на право владения, и свободен от каких-либо притязаний третьих лиц.", align: :justify, size: 10
      i_text "4.7. Качество поставляемого Товара должно соответствовать требованиям ГОСТов, ОСТов, ТУ завода-изготовителя, иным обязательным требованиям законодательства Республики Казахстан, а также отраслевым нормативным документам, применимым к данному виду продукции. В случае поставки Товара, бывшего в употреблении, он должен быть пригодным для использования по его назначению с учетом допустимого износа.", align: :justify, size: 10
      i_text "4.8. Приемка Запчастей по количеству, качеству и комплектации производится в момент их фактической передачи.", align: :justify, size: 10
      i_text "4.9. Поставщик предоставляет гарантию на Товар сроком 12 (двенадцать) месяцев с даты подписания Акта приема-передачи, если иной срок не установлен Спецификацией.", align: :justify, size: 10
      move_down 10

      i_text "5. Ответственность Сторон", style: :bold, size: 11
      i_text "5.1. Стороны несут ответственность за неисполнение или ненадлежащее исполнение своих обязательств по настоящему Договору в соответствии с действующим законодательством Республики Казахстан.", align: :justify, size: 10
      i_text "5.4. За нарушение сроков поставки Поставщик уплачивает Покупателю неустойку в размере 0,2 % от стоимости непоставленного Товара за каждый день просрочки.", align: :justify, size: 10
      i_text "5.5. В случае нарушения сроков оплаты за Товар Покупатель обязан уплатить Поставщику неустойку в размере 0,1 % от стоимости Товара за каждый день просрочки.", align: :justify, size: 10
      move_down 10

      i_text "9.7. Стороны признают юридическую силу документов, подписанных посредством электронной цифровой подписи (ЭЦП).", align: :justify, size: 10
      move_down 20

      render_requisites_and_signatures(buyer_name, buyer_director)
      start_new_page
      render_appendix_content(number, day, month, year, buyer_name, buyer_director, buyer_basis)
    end

    def render_appendix_content(number, day, month, year, buyer_name, buyer_director, buyer_basis)
      i_text "Приложение №1", align: :right, size: 10
      i_text "к Договору поставки № #{number}", align: :right, size: 10
      i_text "от «#{day}» #{month} #{year} г.", align: :right, size: 10
      move_down 10
      i_text "Спецификация №1", style: :bold, align: :center, size: 14
      move_down 10
      i_text "г. Астана                                                                    «#{day}» #{month} #{year} г.", align: :center, size: 10
      move_down 15

      spec_preamble = "#{buyer_name}, именуемое в дальнейшем «Покупатель», в лице директора #{buyer_director}, действующей на основании #{buyer_basis}, с одной стороны, и ТОО «Komandeer Supply», именуемое в дальнейшем «Поставщик», в лице Директора Командирова А.М., действующего на основании Устава, с другой стороны, настоящим удостоверяем соглашение о поставке Товара по Договору № #{number}."
      i_text spec_preamble, align: :justify, size: 10
      move_down 10

      i_text "Поставщик по настоящей Спецификации поставляет следующие Товары:", size: 10
      move_down 10

      render_items_table

      move_down 10
      total_sum = @order.total_amount
      
      if @order.discount_amount.to_f > 0
        original_sum = total_sum + @order.discount_amount
        i_text "Сумма без скидки: #{ActionController::Base.helpers.number_to_currency(original_sum, unit: "тенге", separator: ",", delimiter: " ", format: "%n %u")}", size: 10
        i_text "Скидка (#{@order.discount_percent}%): -#{ActionController::Base.helpers.number_to_currency(@order.discount_amount, unit: "тенге", separator: ",", delimiter: " ", format: "%n %u")}", size: 10
      end

      i_text "Общая сумма спецификации (к оплате): #{ActionController::Base.helpers.number_to_currency(total_sum, unit: "тенге", separator: ",", delimiter: " ", format: "%n %u")}, с НДС.", style: :bold, size: 10
      move_down 10
      i_text "2. Покупатель производит предоплату в размере 100 %.", align: :justify, size: 10
      
      move_down 30
      render_requisites_and_signatures(buyer_name, buyer_director, is_appendix: true)
    end

    def render_items_table
      items = @order.order_items.map.with_index(1) do |item, index|
        p_price = item.product&.price || 0
        effective_price = item.price.to_f > 0 ? item.price.to_f : p_price
        
        name_str = item.product&.name || ""
        uids = Array(item.assigned_uids).reject(&:blank?)
        name_str += "\nUID: #{uids.join(', ')}" if uids.any?

        [
          index.to_s,
          name_str,
          "шт.",
          item.quantity.to_s,
          ActionController::Base.helpers.number_to_currency(effective_price, unit: "", separator: ",", delimiter: " ", precision: 2).strip,
          ActionController::Base.helpers.number_to_currency(item.quantity * effective_price, unit: "", separator: ",", delimiter: " ", precision: 2).strip
        ]
      end
      items_data = [["№", "Наименование", "Ед. изм.", "Кол-во", "Цена (тг)", "Сумма (тг)"]] + items
      indent(25) do
        table(items_data, header: true, width: 495) do
          row(0).style(font_style: :bold, background_color: "EEEEEE", align: :center, size: 9)
          cells.borders = [:bottom, :top, :left, :right]
          cells.padding = 4
          cells.size = 9
          column(0).width = 30
          column(2).width = 50
          column(3).width = 50
        end
      end
    end

    def render_requisites_and_signatures(buyer_name, buyer_director, is_appendix: false)
      title = is_appendix ? "Реквизиты и подписи Сторон" : "10. Реквизиты и подписи Сторон"
      i_text title, style: :bold, size: 12, align: :center
      move_down 15
      y_pos = cursor
      bounding_box([25, y_pos], width: 250) do
        text "ПОСТАВЩИК", style: :bold, size: 10
        text "ТОО «Komandeer Supply»", size: 9
        text "БИН: 100740004791", size: 9
        move_down 15
        text "Директор _____________ Командиров А.М.", size: 9
      end
      bounding_box([290, y_pos], width: 250) do
        req = @order.company_requisite
        text "ПОКУПАТЕЛЬ", style: :bold, size: 10
        text "Наименование: #{buyer_name}", size: 9
        text "БИН: #{req&.bin || @order.user.bin || '________________'}", size: 9
        move_down 15
        text "Директор _____________ #{buyer_director}", size: 9
      end
    end

    def i_text(content, options = {})
      text "#{@indent}#{content}", options
    end
  end
end
