require "test_helper"

class Api::V1::OrdersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user)
    @admin = create(:user, :admin)
    sign_in @user
    @headers = auth_headers(@user)
  end

  test "should get index" do
    create_list(:order, 3, user: @user)
    
    get api_v1_orders_url, headers: @headers, as: :json
    unless response.successful?
      puts "Index Response: #{response.code}"
      puts response.body
    end
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

  test "sign_contract should trigger 1C integration" do
    order = create(:order, user: @user, status: 'pending_director_signature')
    
    # We need to ensure the order is in a state where sign_contract can be called (pending_signature)
    # The factory sets status, but we might need to manually progress if state machine enforces it.
    # Our controller action `sign_contract` calls `IDocs::ContractSigner`.
    # `IDocs::ContractSigner` updates status to `pending_payment` and returns success: true.
    
    # Mock OneC::PaymentTrigger to verify it is called
    mock_trigger = Minitest::Mock.new
    mock_trigger.expect :call, true
    
    OneC::PaymentTrigger.stub :new, mock_trigger do
      post sign_contract_api_v1_order_url(order), headers: @headers, as: :json
      assert_response :success
      
      json_response = JSON.parse(response.body)
      assert json_response['success']
    end
    
    assert_mock mock_trigger
  end
end
