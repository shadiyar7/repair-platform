class OrderContractService
  def initialize(order)
    @order = order
  end

  def call
    @order.with_lock do
      # Idempotency: skip if already assigned uids to all items
      # This allows safe retries of the job
      assign_uids! unless uids_already_assigned?
      
      # Generate and attach PDF
      generate_and_attach_contract!
    end

    true
  rescue => e
    Rails.logger.error "OrderContractService Error [Order ##{@order.id}]: #{e.message}"
    raise e # Re-raise for ActiveJob retry mechanism if configured, though we might want to handle it specifically
  end

  private

  def uids_already_assigned?
    @order.order_items.all? { |item| item.assigned_uids.present? }
  end

  def assign_uids!
    @order.order_items.each do |item|
      item.assign_uids_from_product!
    end
  end

  def generate_and_attach_contract!
    pdf_content = Pdf::ContractGenerator.new(@order).generate
    @order.document.attach(
      io: StringIO.new(pdf_content),
      filename: "Dogovor_#{@order.id}.pdf",
      content_type: 'application/pdf'
    )
  end
end
