class CommercialProposalService
  def initialize(products_data, client_name: nil, director_name: nil)
    @products = products_data
    @client_name = client_name
    @director_name = director_name
  end

  def generate
    generator = Pdf::CommercialProposalGenerator.new(@products, client_name: @client_name, director_name: @director_name)
    generator.generate
  end
end
