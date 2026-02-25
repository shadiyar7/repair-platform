class CommercialProposalService
  def initialize(products_data, client_name: nil)
    @products = products_data
    @client_name = client_name
  end

  def generate
    generator = Pdf::CommercialProposalGenerator.new(@products, client_name: @client_name)
    generator.generate
  end
end
