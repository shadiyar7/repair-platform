require "test_helper"

class WarehouseTest < ActiveSupport::TestCase
  test "should be valid with valid attributes" do
    warehouse = Warehouse.new(name: "Test Warehouse", external_id_1c: 123, address: "Test Address")
    assert warehouse.valid?
  end

  test "should require name" do
    warehouse = Warehouse.new(external_id_1c: 123)
    assert_not warehouse.valid?
    assert_includes warehouse.errors[:name], "can't be blank"
  end

  test "should require external_id_1c" do
    warehouse = Warehouse.new(name: "Test")
    assert_not warehouse.valid?
    assert_includes warehouse.errors[:external_id_1c], "can't be blank"
  end

  test "should require integer external_id_1c" do
    warehouse = Warehouse.new(name: "Test", external_id_1c: "abc")
    assert_not warehouse.valid?
    assert_includes warehouse.errors[:external_id_1c], "is not a number"
  end

  test "should enforce unique external_id_1c" do
    Warehouse.create!(name: "W1", external_id_1c: 999)
    duplicate = Warehouse.new(name: "W2", external_id_1c: 999)
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:external_id_1c], "has already been taken"
  end
end
