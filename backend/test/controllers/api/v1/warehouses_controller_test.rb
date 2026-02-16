require "test_helper"

class Api::V1::WarehousesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user)
    @warehouse = create(:warehouse)
    @headers = auth_headers(@user)
  end

  test "should get index" do
    get api_v1_warehouses_url, headers: @headers, as: :json
    assert_response :success
    
    json_response = JSON.parse(response.body)
    assert_includes json_response, "data"
    assert_kind_of Array, json_response["data"]
    
    if json_response["data"].any?
      first_warehouse = json_response["data"].first
      assert_equal "warehouse", first_warehouse["type"]
      assert_includes first_warehouse["attributes"], "name"
      assert_includes first_warehouse["attributes"], "external_id_1c"
    end
  end

  test "should show warehouse" do
    get api_v1_warehouse_url(@warehouse), headers: @headers, as: :json
    assert_response :success
    
    json_response = JSON.parse(response.body)
    assert_includes json_response, "data"
    assert_equal "warehouse", json_response["data"]["type"]
    assert_equal @warehouse.id.to_s, json_response["data"]["id"]
  end
end
