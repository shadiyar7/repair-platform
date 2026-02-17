require "test_helper"

class CommercialProposalServiceTest < ActiveSupport::TestCase
  test "generates a valid PDF" do
    products_data = [
      { name: "Test Product 1", quantity: 2, price: 1500, total: 3000 },
      { name: "Test Product 2", quantity: 1, price: 5000, total: 5000 }
    ]

    service = CommercialProposalService.new(products_data)
    pdf_content = service.generate

    assert_not_nil pdf_content
    assert pdf_content.start_with?("%PDF"), "Output should be a PDF file"
    assert pdf_content.bytesize > 0
  end
end
