require "test_helper"

class Api::V1::Auth::RegistrationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    Rails.application.reload_routes!
  end

  test "should sign up user" do
    puts "DEBUG URL: #{api_v1_auth_signup_url}"
    assert_difference("User.count") do
      post api_v1_auth_signup_url, params: { 
        email: "newuser@example.com", 
        password: "password123", 
        password_confirmation: "password123",
        role: "client"
      }, as: :json
    end

    assert_response :created
    json_response = JSON.parse(response.body)
    assert_not_nil json_response['token']
    
    # Check if user is unconfirmed
    new_user = User.last
    assert_nil new_user.confirmed_at
    assert_not_nil new_user.confirmation_token
  end

  test "should fail with invalid params" do
    assert_no_difference("User.count") do
      post api_v1_auth_signup_url, params: { 
        email: "", 
        password: "password123" 
      }, as: :json
    end
    
    assert_response :unprocessable_entity
  end
end
