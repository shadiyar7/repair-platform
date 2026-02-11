class Api::V1::OrdersController < ApplicationController
  before_action :authenticate_user!, except: [:by_token]
  before_action :set_order, only: %i[show update checkout sign_contract director_sign pay find_driver assign_driver driver_arrived start_trip deliver complete download_invoice download_contract]

  def index
    orders = case current_user&.role
             when 'admin', 'warehouse'
               Order.all
             when 'driver'
               Order.where(driver: current_user).or(Order.where(status: 'at_warehouse'))
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

  def director_sign
    authorize @order, :update? # Ensure Director can update
    @order.director_sign!
    render json: OrderSerializer.new(@order).serializable_hash
  end

  def sign_contract
    authorize @order, :update?
    service = IDocs::ContractSigner.new(@order)
    result = service.call
    render json: result
  end

  def download_invoice
    authorize @order, :show?
    pdf = OneC::InvoiceGenerator.new(@order).send(:generate_pdf)
    send_data pdf, filename: "invoice_#{@order.id}.pdf", type: "application/pdf"
  end

  def download_contract
    authorize @order, :show?
    
    unless @order.document.attached?
      # Generate on the fly if missing (fallback)
      generate_and_attach_contract(@order)
    end
    
    # Redirect to Yandex S3 presigned URL
    redirect_to @order.document.url(expires_in: 5.minutes), allow_other_host: true
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
    params.require(:order).permit(:delivery_address, :delivery_notes, :company_requisite_id, order_items_attributes: [:product_id, :quantity])
  end
end
