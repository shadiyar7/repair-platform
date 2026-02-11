module Pdf
  class ContractGenerator
    include Prawn::View

    def initialize(order)
      @order = order
      @document = Prawn::Document.new(page_size: 'A4', margin: 40)
      
      # Use a font that supports Cyrillic. 
      # Prawn by default doesn't support Cyrillic well without a font.
      # We need to ensure we have a font or use a default one if available.
      # Ideally we should load a font file. For now, let's try to use a standard one if possible
      # or assumes the system has one. 
      # ACTUALLY, Prawn needs a TTF file for Cyrillic.
      # I will check if there are fonts in assets or vendor.
      # If not, I will try to use a standard path or download one.
      # For safety in this environment, I'll try to use a standard font path or fallback.
      
      font_families.update("OpenSans" => {
        normal: "/System/Library/Fonts/Supplemental/Arial.ttf", # Mac specific or local fallback
        bold: "/System/Library/Fonts/Supplemental/Arial Bold.ttf"
      }) rescue nil
      
      # Fallback to built-in if system font not found (might show boxes for Cyrillic)
      # In a real app we'd bundle the font.
    end

    def generate
      # Attempt to use a Cyrillic compatible font
      # Since we are on Mac (User OS), let's try standard paths
      if File.exist?("/System/Library/Fonts/Supplemental/Arial.ttf")
        font "/System/Library/Fonts/Supplemental/Arial.ttf"
      elsif File.exist?("/System/Library/Fonts/Helvetica.ttc")
        font "/System/Library/Fonts/Helvetica.ttc"
      end

      text "ДОГОВОР ПОСТАВКИ № #{@order.id}", size: 16, style: :bold, align: :center
      move_down 10
      text "г. Алматы                                                                                                   #{Date.today.strftime('%d.%m.%Y')} г.", align: :center
      move_down 20

      text_content = "ТОО «DYNAMIX», именуемое в дальнейшем «Поставщик», в лице Директора ___________________, действующего на основании Устава, с одной стороны, и
#{@order.company_requisite&.company_name || @order.user.company_name || 'Покупатель'}, именуемое в дальнейшем «Покупатель», в лице Директора #{@order.company_requisite&.director_name || @order.user.director_name || '___________________'}, действующего на основании #{@order.company_requisite&.acting_on_basis || 'Устава'}, с другой стороны, заключили настоящий Договор о нижеследующем:"

      text text_content, align: :justify, leading: 5
      move_down 20

      text "1. ПРЕДМЕТ ДОГОВОРА", style: :bold
      text "1.1. Поставщик обязуется передать в собственность Покупателя, а Покупатель принять и оплатить Товар согласно Спецификации:", align: :justify
      move_down 10

      # Table
      items = @order.order_items.map.with_index(1) do |item, index|
        [
          index.to_s,
          item.product&.name,
          "шт.",
          item.quantity.to_s,
          item.price.to_f.round(2).to_s,
          (item.quantity * item.price.to_f).round(2).to_s
        ]
      end

      items_data = [["№", "Наименование", "Ед. изм.", "Кол-во", "Цена", "Сумма"]] + items
      
      table(items_data, header: true, width: 500) do
        row(0).style(font_style: :bold, background_color: "EEEEEE")
        cells.borders = [:bottom, :top, :left, :right]
      end

      move_down 10
      text "Итого: #{@order.total_amount} тенге", style: :bold, align: :right

      move_down 20
      text "2. АДРЕСА И РЕКВИЗИТЫ СТОРОН", style: :bold
      move_down 10

      y_position = cursor
      bounding_box([0, y_position], width: 250) do
        text "ПОСТАВЩИК:", style: :bold
        text "ТОО «DYNAMIX»"
        text "БИН: 123456789012" # Placeholder
        text "Адрес: г. Алматы, ул. Примерная 1"
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

      render
    end
  end
end
