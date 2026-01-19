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
    pdf = IDocs::ContractSigner.new(@order).generate_contract_pdf
    send_data pdf, filename: "contract_#{@order.id}.pdf", type: "application/pdf"
  end

  def pay
    authorize @order, :update?
    @order.pay! if @order.pending_payment?
    # Trigger driver search automatically after payment? Or manual?
    # Requirement: "Status: Waiting for payment" -> "Payment" -> "Search Driver"
    render json: { message: "Payment successful", status: @order.status }
  end

  def find_driver
    authorize @order, :update?
    service = Logistics::DriverFinder.new(@order)
    result = service.call
    render json: result
  end

  # Debug endpoint to force driver assignment
  def assign_driver
    authorize @order, :update?
    # Expected params: driver_name, driver_phone, driver_car_number, driver_arrival_time
    @order.update(
      driver_name: params[:driver_name],
      driver_phone: params[:driver_phone],
      driver_car_number: params[:driver_car_number],
      driver_arrival_time: params[:driver_arrival_time]
    )
    @order.assign_driver!
    render json: OrderSerializer.new(@order).serializable_hash
  end

  def driver_arrived
    authorize @order, :update?
    @order.driver_arrived!
    render json: OrderSerializer.new(@order).serializable_hash
  end

  def start_trip
    authorize @order, :update?
    @order.start_trip!
    render json: OrderSerializer.new(@order).serializable_hash
  end

  def deliver
    authorize @order, :update?
    @order.deliver!
    render json: OrderSerializer.new(@order).serializable_hash
  end

  def complete
    authorize @order, :update?
    @order.complete!
    render json: OrderSerializer.new(@order).serializable_hash
  end

  private

  def assign_company_requisites
    return unless params[:order][:requisites].present?

    requisites_params = params.require(:order).require(:requisites).permit(
      :company_name, :bin, :legal_address, :actual_address, 
      :director_name, :acting_on_basis, :inn, :phone,
      bank_details: [:bank_name, :iban, :swift, :kbe]
    )

    # Serialize bank_details/flatten or store as fields. 
    # Current CompanyRequisite model has flattened fields.
    
    attributes = requisites_params.except(:bank_details)
    
    if requisites_params[:bank_details]
      attributes[:iban] = requisites_params[:bank_details][:iban]
      attributes[:swift] = requisites_params[:bank_details][:swift]
      attributes[:kbe] = requisites_params[:bank_details][:kbe]
    end

    # Find existing requisite or create new one for the user
    # We match by BIN to avoid duplicates for the same user
    company_requisite = current_user.company_requisites.find_or_initialize_by(bin: attributes[:bin])
    company_requisite.update!(attributes)

    @order.update!(company_requisite: company_requisite)
  end

  def set_order
    @order = Order.find(params[:id])
  end

  def order_params
    params.require(:order).permit(:delivery_address, :delivery_notes, :company_requisite_id, order_items_attributes: [:product_id, :quantity])
  end
end
