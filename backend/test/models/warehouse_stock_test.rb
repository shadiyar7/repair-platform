require "test_helper"

class WarehouseStockTest < ActiveSupport::TestCase
  test "valid factory" do
    assert build(:warehouse_stock).valid?
  end

  test "invalid without warehouse" do
    stock = build(:warehouse_stock, warehouse: nil)
    assert_not stock.valid?
  end

  test "invalid without sku" do
    stock = build(:warehouse_stock, product_sku: nil)
    assert_not stock.valid?
  end

  test "validates quantity numericality" do
    stock = build(:warehouse_stock, quantity: -1)
    assert_not stock.valid?

    stock.quantity = 0
    assert stock.valid?
  end
end
