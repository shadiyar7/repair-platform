namespace :one_c do
  desc "Update Product names based on 1C Invoice #00000000053"
  task sync_invoice_names: :environment do
    puts "Starting 1C Invoice Name Sync..."

    # Mapping: nomenclature_code => name
    products_map = {
      "00000000016" => "Автосцепка",
      "00000000019" => "Хомут тяговый 106.00.001-2",
      "00000000035" => "Рама боковая ЧЛЗ-100.00.020-4СБ",
      "00000000054" => "Колесо цельнокатаное 975*175 ГОСТ 10791-2011",
      "00000000060" => "Колесная пара СОНК",
      "00000000062" => "Рама боковая",
      "00000000083" => "Лом черного металла",
      "00000000115" => "Балка надрессорная ГОСТ 32400–2013, бывшие в употреблении,производство не ранее 1997 года",
      "00000000140" => "Надрессорная балка",
      "00000000147" => "Кислород",
      "00000000207" => "Хомуты,ремонтопригодные",
      "00000000389" => "Подшипник в сборе",
      "00000000495" => "Боковая рама 11-15 лет, ремонтопригодная",
      "00000000496" => "Надрессорная балка,11-15 лет",
      "00000000497" => "Надрессорная балка,16-20 лет",
      "00000000411" => "Тарельчатая шайба",
      "00000000557" => "Колесные пары",
      "00000000558" => "Поглощающий аппарат",
      "00000000559" => "Трангель",
      "00000000571" => "Штурвал",
      "00000000574" => "Тормозной цилиндр",
      "00000000575" => "Рабочая камера",
      "00000000576" => "Авторежим",
      "00000000577" => "Авторегулятор",
      "00000000578" => "Запасной резервуар",
      "00000000579" => "Краны концевые",
      "00000000580" => "Разобщительный кран",
      "00000000581" => "Тормозные тяги",
      "00000000583" => "Балка авторежима",
      "00000000584" => "Разгрузочное устройство",
      "00000000585" => "Разгрузочные люка",
      "00000000586" => "Загрузочные люка",
      "00000000587" => "Лестница",
      "00000000588" => "Лом",
      "00000000438" => "Колесная пара с осью РУ-1 и с буксовым узлом, бывшая в употреблении, брак. Не пригодна к дальнейшей эксплуатации, передаётся исключительно для целей утилизации/разборки.",
      "00000000243" => "колесная пара",
      "00000000255" => "Колесо цельнокатаное 957*175 ГОСТ 10791-2011",
      "00000000300" => "Ось чистовая",
      "00000000310" => "Внутреннее кольцо переднее",
      "00000000311" => "Внутреннее кольцо заднее"
    }

    # Ensure warehouse exists
    warehouse = Warehouse.find_or_initialize_by(external_id_1c: 1) 
    
    if warehouse.new_record?
      warehouse.name = "Основной склад (1С)"
      warehouse.address = "г. Астана, пр. Туран 46/2" # From invoice
      warehouse.save!
      puts "Created Warehouse: #{warehouse.name} (ID: #{warehouse.external_id_1c})"
    else
      puts "Found Warehouse: #{warehouse.name}"
    end

    products_map.each do |code, name|
      # Find or Initialize Product
      product = Product.find_or_initialize_by(nomenclature_code: code)
      
      product.name = name
      product.is_active = true
      
      # If new or price is missing, set random price
      if product.new_record? || product.price.to_f.zero?
        product.price = rand(100..50000)
        product.category = "Запчасти" if product.category.blank?
        product.sku = "WS-#{code}" if product.sku.blank?
        puts "Creating/Updating Product: #{code} -> #{name} (Price: #{product.price})"
      else
        puts "Updating Name for Product: #{code} -> #{name}"
      end
      
      if product.save
        # Ensure Warehouse Stock
        # Find ANY existing stock record that matches either:
        # 1. nomenclature_code: code (The new way)
        # 2. product_sku: product.sku (Existing correct SKU)
        # 3. product_sku: code (If stock stored raw 1C code instead of proper SKU)
        
        stock = WarehouseStock.where(warehouse: warehouse)
                              .where("nomenclature_code = :code OR product_sku = :sku OR product_sku = :code", code: code, sku: product.sku)
                              .first

        # If still not found, initialize new
        stock ||= WarehouseStock.new(warehouse: warehouse)
        
        # Update attributes - Be careful not to create a NEW duplicate if we didn't find one but validation finds another?
        # Unlikely with above query.
        
        stock.nomenclature_code = code
        stock.product_sku = product.sku
        
        if stock.quantity.to_f <= 0
           stock.quantity = rand(10..200)
        end
        stock.synced_at = Time.current
        stock.save!
      else
        puts "Error saving product #{code}: #{product.errors.full_messages.join(', ')}"
      end
    end

    puts "Sync Completed!"
  end
end
