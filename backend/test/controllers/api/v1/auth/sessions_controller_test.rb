require "test_helper"

class Api::V1::Auth::SessionsControllerTest < ActionDispatch::IntegrationTest
  test "should login with valid credentials" do
    user = create(:user, password: "password123")
    
    post api_v1_auth_login_password_url, params: { email: user.email, password: "password123" }, as: :json
    
    assert_response :success
    # Check cookie or header. Since controller sets cookie explicitly:
    assert response.cookies['jwt'].present? || response.headers['Authorization'].present?
    
    json_response = JSON.parse(response.body)
    assert_equal user.email, json_response['user']['data']['attributes']['email']
  end

  test "should fail login with invalid password" do
    user = create(:user, password: "password123")
    
    post api_v1_auth_login_password_url, params: { email: user.email, password: "wrongpassword" }, as: :json
    
    assert_response :unauthorized
  end
end
