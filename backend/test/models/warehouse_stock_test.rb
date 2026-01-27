require "test_helper"

class WarehouseStockTest < ActiveSupport::TestCase
  setup do
    @warehouse = Warehouse.create!(name: "Stock Test Warehouse", external_id_1c: 100)
  end

  test "should be valid with valid attributes" do
    stock = WarehouseStock.new(warehouse: @warehouse, product_sku: "SKU123", quantity: 10)
    assert stock.valid?
  end

  test "should require product_sku" do
    stock = WarehouseStock.new(warehouse: @warehouse, quantity: 10)
    assert_not stock.valid?
  end

  test "should require valid quantity" do
    stock = WarehouseStock.new(warehouse: @warehouse, product_sku: "SKU123", quantity: -1)
    assert_not stock.valid?
  end
end
