class Api::V1::OrdersController < ApplicationController
  before_action :authenticate_user!, except: [:by_token]
  before_action :set_order, only: %i[show update checkout sign_contract director_sign pay find_driver assign_driver driver_arrived start_trip deliver complete download_invoice download_contract upload_receipt confirm_payment]

  def index
    orders = case current_user&.role
             when 'warehouse'
               if current_user.warehouse
                 # Relaxed filtering: Show all active orders for now to ensure visibility
                 # TODO: Re-enable strict warehouse filtering once product data is clean
                 Order.includes(:company_requisite, order_items: :product)
                      .joins(order_items: :product)
                      .where(status: ['paid', 'searching_driver', 'driver_assigned', 'at_warehouse', 'in_transit'])
                      .distinct
               else
                 Order.where(status: ['at_warehouse', 'searching_driver', 'driver_assigned', 'paid'])
               end
             when 'admin', 'supervisor', 'director'
               Order.includes(:company_requisite, order_items: :product).all
             when 'driver'
               # Drivers see orders that are either explicitly 'searching_driver' OR 'payment_review' (Pre-search)
               Order.where(driver: current_user).or(Order.where(status: ['at_warehouse', 'searching_driver', 'payment_review']))
             when nil
               []
             else
               current_user.orders
             end
    render json: OrderSerializer.new(orders).serializable_hash
  end

  def by_token
    @order = Order.find_by!(smart_link_token: params[:token])
    render json: OrderSerializer.new(@order).serializable_hash
  end

  def generate_smart_link
    authorize @order, :update?
    
    if @order.smart_link_token.nil?
      @order.update(smart_link_token: SecureRandom.hex(10))
    end
    
    render json: { 
      smart_link_token: @order.smart_link_token,
      url: "#{request.base_url}/track/#{@order.smart_link_token}" # Returning full URL for convenience
    }
  end



  def show
    authorize @order
    render json: OrderSerializer.new(@order).serializable_hash
  end

  def create
    @order = current_user.orders.build(order_params)
    @order.status = 'cart'
    
    if @order.save
      assign_company_requisites if params[:order][:requisites].present?
      
      # Auto-transition if requisites are present
      if @order.company_requisite.present?
        @order.submit_requisites!
      end

      render json: OrderSerializer.new(@order).serializable_hash, status: :created
    else
      render json: @order.errors, status: :unprocessable_entity
    end
  end

  def update
    authorize @order
    if @order.update(order_params)
      render json: OrderSerializer.new(@order).serializable_hash
    else
      render json: @order.errors, status: :unprocessable_entity
    end
  end

  def checkout
    authorize @order, :update?
    @order.checkout! if @order.cart?
    # Simulate contract generation
    render json: { message: "Contract generated", contract_url: "..." }
  end

  def upload_receipt
    authorize @order, :update?
    
    amount = params[:amount].to_f
    file = params[:file]

    if file.nil?
      render json: { error: "File is required" }, status: :unprocessable_entity
      return
    end

    # Verify Amount (Allowing small float difference?)
    if (amount - @order.total_amount.to_f).abs > 1.0
       render json: { error: "Сумма не совпадает с итогом заказа (#{@order.total_amount})" }, status: :unprocessable_entity
       return
    end

    @order.payment_receipt.attach(file)
    
    if @order.pending_payment?
      @order.upload_receipt!
      
      # Notify Supervisor
      begin
        SupervisorMailer.new_payment_receipt(@order).deliver_later
      rescue => e
        Rails.logger.error "Failed to send email: #{e.message}"
      end

      # Simulate Della.kz Order Creation
      begin
        DellaService.create_order(@order)
      rescue => e
        Rails.logger.error "Della Simulation Failed: #{e.message}"
      end
    end

    render json: OrderSerializer.new(@order).serializable_hash
  end

  def confirm_payment
    authorize @order, :update?
    @order.update(is_verified: true)
    
    # Try to transition if applicable, but don't error if already searching
    @order.confirm_payment! if @order.may_confirm_payment?

    render json: OrderSerializer.new(@order).serializable_hash
  end

  def assign_driver
    authorize @order, :update?
    
    @order.assign_driver!
    @order.update(
      driver_name: params[:driver_name],
      driver_phone: params[:driver_phone],
      driver_car_number: params[:driver_car_number],
      driver_arrival_time: params[:driver_arrival_time],
      driver_comment: params[:driver_comment],
      delivery_price: params[:delivery_price]
    )

    # Notify Warehouse Manager
    begin
      WarehouseMailer.driver_assigned(@order).deliver_later
    rescue => e
      Rails.logger.error "Failed to notify Warehouse: #{e.message}"
    end

    render json: OrderSerializer.new(@order).serializable_hash
  end

  def driver_arrived
    authorize @order, :update?
    @order.driver_arrived!
    render json: OrderSerializer.new(@order).serializable_hash
  end

  def start_trip
    authorize @order, :update?
    @order.start_trip! # Should set status to in_transit and generate token
    
    # Ensure token exists if not generated by state machine callback
    if @order.smart_link_token.nil?
      @order.update(smart_link_token: SecureRandom.hex(10))
    end

    render json: OrderSerializer.new(@order).serializable_hash
  end

  def director_sign
    authorize @order, :update? # Ensure Director can update
    @order.director_sign!
    render json: OrderSerializer.new(@order).serializable_hash
  end

  def sign_contract
    authorize @order, :update?
    service = IDocs::ContractSigner.new(@order)
    result = service.call
    
    if result[:success]
      # Trigger 1C Integration (Debug or Real)
      # Using verify/debug mode as requested by user ("internal method")
      begin
        OneCPaymentTrigger.new(@order).call
        Rails.logger.info "1C Payment Trigger fired for Order ##{@order.id}"
      rescue => e
        Rails.logger.error "Failed to fire 1C Payment Trigger: #{e.message}"
      end
    end

    render json: result
  end

  def download_invoice
    authorize @order, :show?
    pdf = OneC::InvoiceGenerator.new(@order).send(:generate_pdf)
    send_data pdf, filename: "invoice_#{@order.id}.pdf", type: "application/pdf"
  end

  def download_contract
    authorize @order, :show?
    
    # Generate only if missing
    unless @order.document.attached?
      generate_and_attach_contract(@order)
    end
    
    timestamp = Time.current.strftime('%H%M%S')
    
    # PROXY MODE: Download from S3 and send to client to avoid CORS issues
    # and ensure correct filename/content type.
    send_data @order.document.download,
              filename: "Dogovor_#{@order.id}_#{timestamp}.pdf",
              type: 'application/pdf',
              disposition: 'inline'
  end

  private

  def generate_and_attach_contract(order)
    pdf_content = Pdf::ContractGenerator.new(order).generate
    order.document.attach(
      io: StringIO.new(pdf_content),
      filename: "Dogovor_#{order.id}.pdf",
      content_type: 'application/pdf'
    )
  end

  def assign_company_requisites
    return unless params[:order][:requisites].present?

    requisites_params = params.require(:order).require(:requisites).permit(
      :company_name, :bin, :legal_address, :actual_address, 
      :director_name, :acting_on_basis, :inn, :phone,
      bank_details: [:bank_name, :iban, :swift, :kbe]
    )

    attributes = requisites_params.except(:bank_details)
    
    if requisites_params[:bank_details]
      attributes[:iban] = requisites_params[:bank_details][:iban]
      attributes[:swift] = requisites_params[:bank_details][:swift]
      attributes[:kbe] = requisites_params[:bank_details][:kbe]
    end

    company_requisite = current_user.company_requisites.find_or_initialize_by(bin: attributes[:bin])
    company_requisite.update!(attributes)

    @order.update!(company_requisite: company_requisite)
    
    # Generate Contract immediately after assigning requisites
    generate_and_attach_contract(@order)
  end

  def set_order
    @order = Order.find(params[:id])
  end

  def order_params
    params.require(:order).permit(:city, :delivery_address, :delivery_notes, :company_requisite_id, order_items_attributes: [:product_id, :quantity])
  end
end
