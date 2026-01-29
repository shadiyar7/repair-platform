require "test_helper"

module Api
  module V1
    module Integrations
      module OneC
        class StocksControllerTest < ActionDispatch::IntegrationTest
          setup do
            @warehouse = Warehouse.create!(name: "Test Warehouse", external_id_1c: 777)
            @product = products(:one) # Assumes fixture exists, or we create one
            # Create product manually if fixture fails
            @product ||= Product.create!(
              name: "Test Product", 
              sku: "TEST-SKU-1", 
              price: 100, 
              category: "Test",
              stock: 0
            )
          end

          test "should update stocks from valid 1C payload" do
            payload = {
              warehouse_id_1c: 777,
              items: [
                { nomenclature_code: @product.sku, quantity: 50.5 },
                { nomenclature_code: "NEW-SKU", quantity: 10 } # Product that doesn't exist in our DB yet
              ]
            }

            assert_difference("WarehouseStock.count", 2) do
              post api_v1_integrations_one_c_stocks_url, params: payload, as: :json
            end

            assert_response :success
            
            # Verify WarehouseStock updated
            stock = @warehouse.warehouse_stocks.find_by(product_sku: @product.sku)
            assert_equal 50.5, stock.quantity
            assert_not_nil stock.synced_at

            # Verify Legacy Product updated
            @product.reload
            # assert_equal 50, @product.stock # Disabled by user request
          end

          test "should get stocks list merged with products" do
             # Seed some data
             stock = WarehouseStock.create!(warehouse: @warehouse, product_sku: @product.sku, quantity: 77)
             # Ensure product is active
             @product.update!(is_active: true)

             get api_v1_integrations_one_c_stocks_url, as: :json
             assert_response :success
             
             json_response = JSON.parse(response.body)
             assert_equal @warehouse.name, json_response["warehouse"]
             assert_equal 1, json_response["items"].length
             
             item = json_response["items"][0]
             assert_equal "77.0", item["quantity"]
             assert_equal @product.name, item["name"]
             assert_equal @product.sku, item["sku"]
          end

          test "should hide inactive items" do
             stock = WarehouseStock.create!(warehouse: @warehouse, product_sku: @product.sku, quantity: 77)
             @product.update!(is_active: false)
             
             get api_v1_integrations_one_c_stocks_url, as: :json
             json_response = JSON.parse(response.body)
             assert_equal 0, json_response["items"].length
          end

          test "should return error for missing warehouse" do
            payload = { warehouse_id_1c: 99999, items: [] }
            post api_v1_integrations_one_c_stocks_url, params: payload, as: :json
            assert_response :not_found
          end

          test "should return error for invalid payload" do
            post api_v1_integrations_one_c_stocks_url, params: {}, as: :json
            assert_response :bad_request
          end
        end
      end
    end
  end
end
