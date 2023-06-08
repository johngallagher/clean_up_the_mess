ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
require 'rails/test_help'

Dir.glob("./test/support/**/*.rb").each { |f| require f }

class ActiveSupport::TestCase
  fixtures :all

  def is_logged_in?
    !session[:user_id].nil?
  end

  def log_in_as(user)
    session[:user_id] = user.id
  end
end

class ActionDispatch::IntegrationTest
  def log_in_as(
    user,
    password: 'password',
    remember_me: '1',
    matching_policy: :allow
  )
    VCR.use_cassette("log_in_user_policy_action_#{matching_policy}_email_#{user.email}") do
      post login_path, params: {
        castle_request_token: "test|device:chrome_on_mac|policy.action:#{matching_policy}",
        session: {
          email: user.email,
          password: password,
          remember_me: remember_me
        }
      }
    end
  end
end

require 'webdrivers'
Webdrivers::Chromedriver.update

VCR.configure do |config|
  config.ignore_hosts '127.0.0.1'
  config.cassette_library_dir = 'test/vcr'
  config.hook_into :webmock
  config.filter_sensitive_data('<BASIC_AUTH_ENCODED_CASTLE_API_SECRET>') do
    Base64.encode64(":#{ENV.fetch('CASTLE_API_SECRET')}").chomp
  end
  config.filter_sensitive_data('<CLOUDFLARE_API_TOKEN>') { ENV.fetch('CLOUDFLARE_API_TOKEN') }
  config.filter_sensitive_data('<CLOUDFLARE_API_EMAIL>') { ENV.fetch('CLOUDFLARE_API_EMAIL') }
  config.allow_http_connections_when_no_cassette = false
end
