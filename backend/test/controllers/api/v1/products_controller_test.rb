require "test_helper"

class Api::V1::ProductsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user)
    @headers = auth_headers(@user)
    @product = create(:product) 
  end

  test "should get index" do
    create_list(:product, 2)
    
    get api_v1_products_url, headers: @headers, as: :json
    assert_response :success
    
    json_response = JSON.parse(response.body)
    # create(:product) in setup + 2 in test = 3. Plus maybe fixtures.
    assert_operator json_response['data'].length, :>=, 3
  end

  test "should show product" do
    get api_v1_product_url(@product), headers: @headers, as: :json
    if response.status == 404
       puts "DEBUG SHOW: #{response.body}" 
    end
    assert_response :success
    
    json_response = JSON.parse(response.body)
    assert_equal @product.id.to_s, json_response['data']['id']
    assert_equal @product.name, json_response['data']['attributes']['name']
  end

  test "should allow public access" do
    get api_v1_products_url, as: :json
    assert_response :success
  end
end
