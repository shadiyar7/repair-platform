require "test_helper"
require "securerandom"

class ProfileUpdateTest < ActionDispatch::IntegrationTest
  setup do
    @email = "profile_#{SecureRandom.hex(6)}@example.com"
    @password = "password123"
    
    @user = User.new(
      email: @email,
      password: @password,
      password_confirmation: @password,
      role: 'client',
      company_name: 'Old Company',
      phone: '+77010000000'
    )
    # Skip confirmation email to avoid ActionMailer crashes in test env
    @user.skip_confirmation_notification!
    @user.save!
    @user.confirm
  end

  test "authenticated user can update profile" do
    # 1. Login to get JWT Cookie
    post api_v1_auth_login_password_url, params: {
      email: @email,
      password: @password
    }, as: :json
    assert_response :success
    assert_not_nil cookies['jwt']

    # 2. Update Profile
    new_company = "New Tech LLP"
    new_phone = "+77771234567"
    
    put api_v1_auth_profile_url, params: {
      company_name: new_company,
      phone: new_phone
    }, as: :json
    
    assert_response :success
    
    # 3. Verify Response
    json = JSON.parse(response.body)
    assert_equal "Profile updated successfully", json["message"]
    
    attributes = json["user"]["data"]["attributes"]
    assert_equal new_company, attributes["company_name"]
    assert_equal new_phone, attributes["phone"]
    
    # 4. Verify Database
    @user.reload
    assert_equal new_company, @user.company_name
    assert_equal new_phone, @user.phone
  end

  test "unauthenticated user cannot update profile" do
    put api_v1_auth_profile_url, params: {
      company_name: "Hacker Corp"
    }, as: :json
    
    assert_response :unauthorized
  end
end
