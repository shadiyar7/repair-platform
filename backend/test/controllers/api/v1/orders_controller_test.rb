require "test_helper"

class Api::V1::OrdersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user)
    @admin = create(:user, :admin)
    @headers = auth_headers(@user)
  end

  test "should get index" do
    create_list(:order, 3, user: @user)
    
    get api_v1_orders_url, headers: @headers, as: :json
    assert_response :success
    
    json_response = JSON.parse(response.body)
    assert_equal 3, json_response['data'].length
  end

  test "should create order" do
    product = create(:product)
    
    order_params = {
      order: {
        order_items_attributes: [
          { product_id: product.id, quantity: 2 }
        ]
      }
    }

    assert_difference("Order.count") do
      post api_v1_orders_url, params: order_params, headers: @headers, as: :json
    end

    assert_response :created
    
    json_response = JSON.parse(response.body)
    assert_equal "cart", json_response['data']['attributes']['status']
  end

  test "should show order" do
    order = create(:order, user: @user)
    
    get api_v1_order_url(order), headers: @headers, as: :json
    assert_response :success
    
    json_response = JSON.parse(response.body)
    assert_equal order.id.to_s, json_response['data']['id']
  end

  test "should forbid access without token" do
    get api_v1_orders_url, as: :json
    assert_response :unauthorized
  end
end
