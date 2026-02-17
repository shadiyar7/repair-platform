class CommercialProposalService
  def initialize(products_data)
    @products = products_data
  end

  def generate
    # Render the HTML template with the data
    html_content = ApplicationController.render(
      template: 'api/v1/commercial_proposals/kp_template',
      layout: nil,
      assigns: { products: @products }
    )

    # Convert HTML to PDF using WickedPdf
    pdf_generator = WickedPdf.new
    pdf_data = pdf_generator.pdf_from_string(
      html_content,
      page_size: 'A4',
      margin: { top: 0, bottom: 0, left: 0, right: 0 },
      encoding: 'UTF-8',
      disable_smart_shrinking: true
    )

    pdf_data
  end
end
