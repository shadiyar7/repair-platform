class CommercialProposalService
  def initialize(products_data, current_date = Date.current)
    @products_data = products_data # array of { name: 'Product Name', quantity: 1, price: 1000, total: 1000 }
    @current_date = current_date
    @template_path = Rails.root.join('app', 'views', 'DOC-20260217-WA0026_260217_204956.pdf')
  end

  def generate
    # 1. Load the template PDF
    template_pdf = CombinePDF.load(@template_path.to_s)

    # 2. Create the overlay PDF
    overlay_pdf = Prawn::Document.new(page_size: 'A4', margin: 0) do |pdf|
      # Set font - using a built-in font for now, ideally should load a font that supports Cyrillic
      # attempting to use a standard font, might need a custom ttf for Russian support if not present
      # Using a fallback font strategy if possible or just standard Helvetica
      
      # For Cyrillic support in Prawn, we usually need a TTF font.
      # Checking if we have one, otherwise usage might be limited.
      # Assuming we might need to load a font.
      
      pdf.font_families.update("OpenSans" => {
        normal: "/System/Library/Fonts/Supplemental/Arial.ttf", # Mac fallback
        bold: "/System/Library/Fonts/Supplemental/Arial Bold.ttf", # Mac fallback
        italic: "/System/Library/Fonts/Supplemental/Arial Italic.ttf" # Mac fallback
      }) rescue nil
      
      # Trying to use a font that likely exists or fallback
      begin
        pdf.font "OpenSans"
      rescue
        # Fallback to standard if custom fails, though Cyrillic might not render
      end

      # Coordinates need to be adjusted based on the template
      # Date Overlay (Assumed position: Top Right or specific field)
      pdf.text_box @current_date.strftime("%d.%m.%Y"), at: [400, 750], width: 100, size: 12

      # Company Name Overlay (Assumed position)
      pdf.text_box "DYNAMIX", at: [100, 700], width: 200, size: 14, style: :bold

      # Product Table
      # Assumed position: Middle of the page
      pdf.move_down 300
      
      table_data = [["Наименование", "Кол-во", "Цена", "Сумма"]]
      @products_data.each do |item|
        table_data << [item[:name], item[:quantity].to_s, item[:price].to_s, item[:total].to_s]
      end
      
      pdf.table(table_data, header: true, width: 500, position: :center) do
        row(0).font_style = :bold
        self.row_colors = ["DDDDDD", "FFFFFF"]
        self.header = true
      end
    end

    # 3. Convert Prawn document to CombinePDF
    overlay_combine_pdf = CombinePDF.parse(overlay_pdf.render)

    # 4. Merge overlay into the first page of the template
    # Assuming the template has 1 page or we want to overlay on the first page
    template_pdf.pages.each_with_index do |page, index|
      page << overlay_combine_pdf.pages[index] if overlay_combine_pdf.pages[index]
    end

    # 5. Return PDF data
    template_pdf.to_pdf
  end
end
