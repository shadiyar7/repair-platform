require "test_helper"

class OrderTest < ActiveSupport::TestCase
  test "valid order" do
    order = build(:order)
    assert order.valid?
  end

  test "generates smart link token on create" do
    order = create(:order)
    assert_not_nil order.smart_link_token
  end

  test "calculate_total_amount sums up items" do
    order = create(:order)
    product1 = create(:product, price: 100.0)
    product2 = create(:product, price: 50.0)
    
    create(:order_item, order: order, product: product1, quantity: 2, price: 100.0) # 200
    create(:order_item, order: order, product: product2, quantity: 1, price: 50.0)  # 50
    
    order.order_items.reload
    order.calculate_total_amount
    assert_equal 250.0, order.total_amount
  end

  test "initial state is cart" do
    order = create(:order)
    assert order.cart?
  end

  test "transition flow: checkout -> requisites -> complete" do
    order = create(:order)
    
    assert order.cart?
    
    order.checkout!
    assert order.requisites_selected?
    
    order.prepare_contract!
    assert order.pending_director_signature?

    order.director_sign!
    assert order.pending_signature?
    assert_not_nil order.director_signed_at

    order.sign_contract!
    assert order.pending_payment?

    order.pay!
    assert order.searching_driver?

    order.assign_driver!
    assert order.driver_assigned?
  end
end
