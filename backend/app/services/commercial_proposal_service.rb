class CommercialProposalService
  def initialize(products_data)
    @products = products_data
  end

  def generate
    generator = Pdf::CommercialProposalGenerator.new(@products)
    generator.generate
  end
end
