ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
require 'rails/test_help'

class ActiveSupport::TestCase
  fixtures :all

  # Returns true if a test user is logged in.
  def is_logged_in?
    !session[:user_id].nil?
  end

  # Log in as a particular user.
  def log_in_as(user)
    session[:user_id] = user.id
  end
end

class ActionDispatch::IntegrationTest
  # Log in as a particular user.
  def log_in_as(user, password: 'password', remember_me: '1', likelihood_of_being_a_hacker: 0.0)
    VCR.use_cassette("user_with_hacker_risk_#{likelihood_of_being_a_hacker}") do
      post login_path, params: {
        castle_request_token: "test|device:chrome_on_mac|risk:#{likelihood_of_being_a_hacker}",
        session: { email: user.email,
                  password: password,
                  remember_me: remember_me }
      }
    end
  end
end

VCR.configure do |config|
  config.cassette_library_dir = "spec/vcr"
  config.hook_into :webmock
  config.filter_sensitive_data('<API_KEY>') { ENV['API_KEY'] }
end