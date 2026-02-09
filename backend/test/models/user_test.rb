require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "valid user" do
    user = build(:user)
    assert user.valid?
  end

  test "invalid without role" do
    user = build(:user, role: nil)
    assert_not user.valid?
  end

  test "roles enum" do
    user = build(:user, role: "admin")
    assert user.admin?
    assert_not user.client?
  end

  test "generate_otp! creates code and timestamp" do
    user = create(:user)
    
    # In test env, it should be 111111 (see User model implementation)
    user.generate_otp!
    
    assert_equal "111111", user.otp_attempt
    assert_not_nil user.otp_sent_at
  end

  test "verify_otp returns true for correct code within 5 minutes" do
    user = create(:user)
    user.generate_otp!
    
    assert user.verify_otp("111111")
  end

  test "verify_otp returns false for incorrect code" do
    user = create(:user)
    user.generate_otp!
    
    assert_not user.verify_otp("000000")
  end

  test "verify_otp returns false if expired" do
    user = create(:user)
    user.generate_otp!
    
    # Travel to future
    user.update_column(:otp_sent_at, 6.minutes.ago)
    
    assert_not user.verify_otp("111111")
  end
end
