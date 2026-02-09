require "simplecov"
require "bcrypt"
SimpleCov.start "rails" do
  enable_coverage :branch
  primary_coverage :branch
end

ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "devise/jwt/test_helpers"

module ActiveSupport
  class TestCase
    include FactoryBot::Syntax::Methods
    include Devise::Test::IntegrationHelpers

    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    def auth_headers(user)
      headers = { 'Accept' => 'application/json', 'Content-Type' => 'application/json' }
      Devise::JWT::TestHelpers.auth_headers(headers, user)
    end

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
  end
end
