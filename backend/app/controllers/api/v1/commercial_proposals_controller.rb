module Api
  module V1
    require "prawn/table"    
    class CommercialProposalsController < ApplicationController
      # Allow access without auth if needed, or keep it strict. 
      # User didn't specify, but for "Add to Cart" usually implies client or guest.
      # Let's keep it optional for now or require auth if they want user details.
      # skip_before_action :authenticate_user!, raise: false 

      def create
        items_params = params[:items] # [{ id: 1, quantity: 5 }, ...]
        
        if items_params.blank?
          render json: { error: 'No items provided' }, status: :bad_request
          return
        end

        # Fetch products
        product_ids = items_params.map { |i| i[:id] }
        products = Product.where(id: product_ids).index_by(&:id)

        # Build Line Items
        line_items = []
        total_amount = 0

        items_params.each do |item|
          product = products[item[:id]]
          next unless product
          
          qty = item[:quantity].to_i
          total = qty * product.price
          
          line_items << {
            name: product.name,
            sku: product.sku,
            quantity: qty,
            price: product.price,
            total: total
          }
          total_amount += total
        end

        # Generate PDF
        pdf = Prawn::Document.new
        
        # Register Font for Cyrillic support
        pdf.font_families.update("Arial" => {
          normal: Rails.root.join("app/assets/fonts/Arial.ttf"),
          bold: Rails.root.join("app/assets/fonts/Arial Bold.ttf") 
        })
        pdf.font "Arial"

        # Header
        pdf.font_size 20
        pdf.text "Коммерческое предложение", style: :bold, align: :center
        pdf.move_down 10
        pdf.font_size 12
        pdf.text "DYNAMIX Platform", align: :center, color: "CC0000"
        pdf.move_down 20
        
        # Date & Validity
        pdf.text "Дата: #{Date.today.strftime('%d.%m.%Y')}"
        pdf.text "Действительно до: #{(Date.today + 7.days).strftime('%d.%m.%Y')}"
        pdf.move_down 20

        # Items Table
        table_data = [["Наименование", "Артикул", "Кол-во", "Цена", "Сумма"]]
        line_items.each do |li|
          table_data << [
            li[:name],
            li[:sku],
            li[:quantity].to_s,
            ActionController::Base.helpers.number_to_currency(li[:price], unit: "₸", format: "%n %u", precision: 0),
            ActionController::Base.helpers.number_to_currency(li[:total], unit: "₸", format: "%n %u", precision: 0)
          ]
        end
        
        pdf.table(table_data, header: true, width: pdf.bounds.width) do
          row(0).font_style = :bold
          row(0).background_color = "EEEEEE"
          columns(2..4).align = :right
        end

        pdf.move_down 20
        
        # Total
        pdf.text "Итого к оплате: #{ActionController::Base.helpers.number_to_currency(total_amount, unit: "₸", format: "%n %u", precision: 0)}", size: 16, style: :bold, align: :right

        pdf.move_down 50
        pdf.text "Спасибо за ваш интерес к нашей продукции!", align: :center, size: 10
        pdf.text "Контакты: sales@dynamix.kz | +7 700 000 00 00", align: :center, size: 10

        send_data pdf.render,
          filename: "KP_Dynamix_#{Date.today}.pdf",
          type: "application/pdf",
          disposition: "attachment"
      end
    end
  end
end
