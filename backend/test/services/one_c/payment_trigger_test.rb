require "test_helper"

class OneC::PaymentTriggerTest < ActiveSupport::TestCase
  def setup
    @client = create(:user, :client)
    @company_requisite = create(:company_requisite, user: @client, bin: "123456789012", company_name: "Test Company")
    @order = create(:order, user: @client, company_requisite: @company_requisite, total_amount: 5000)
    @product = create(:product, sku: "PROD-001", price: 1000)
    @order_item = create(:order_item, order: @order, product: @product, quantity: 5, price: 1000)
  end

  test "builds correct payload structure" do
    # Since we are mocking the logger in the service or just testing logic,
    # we can verify the payload construction.
    # The service returns the payload in our implementation (debug mode).
    
    service = OneC::PaymentTrigger.new(@order)
    payload = service.call

    assert_equal "123456789012", payload["binn"]
    assert_equal @order.id, payload["ID"]
    assert_equal "Test Company", payload["companyName"]
    assert_equal "000000001", payload["warehouseId"]
    assert_equal 5000.0, payload["totalPrice"]
    
    assert_equal 1, payload["items"].size
    item = payload["items"].first
    assert_equal "PROD-001", item["nomenclature_code"]
    assert_equal 5, item["quantity"]
    assert_equal 1000.0, item["price"]
  end

  test "handles missing product gracefully" do
    # Create a new item with a product that has no SKU
    product_no_sku = create(:product, sku: nil)
    # Use update_column to bypass any validations if needed, though factory might allow nil if we didn't force it
    product_no_sku.update_columns(sku: nil) 
    
    create(:order_item, order: @order, product: product_no_sku, quantity: 1, price: 500)
    
    # Reload to ensure changes are picked up and we get all items
    @order.reload
    
    service = OneC::PaymentTrigger.new(@order)
    payload = service.call
    
    # We expected "NO_SKU" for the item with missing SKU
    # Find the item for our new product
    item_payload = payload["items"].find { |i| i["price"] == 500.0 }
    assert_equal "NO_SKU", item_payload["nomenclature_code"]
  end
end
