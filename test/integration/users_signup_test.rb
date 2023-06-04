require 'test_helper'

class UsersSignupTest < ActionDispatch::IntegrationTest
  make_my_diffs_pretty!

  def setup
    ActionMailer::Base.deliveries.clear
  end

  test 'invalid signup information' do
    assert_no_difference 'User.count' do
      sign_up_as(
        name: '',
        email: 'user@invalid',
        password: 'foo',
        password_confirmation: 'bar'
      )
    end
    assert_template 'users/new'
    assert_select 'div#error_explanation'
    assert_select 'div.field_with_errors'
  end

  test 'valid signup information with account activation' do
    assert_difference 'User.count', 1 do
      sign_up_as(
        name: 'Example User',
        email: 'user@example.com',
        password: 'password',
        password_confirmation: 'password'
      )
    end
    assert_equal 1, ActionMailer::Base.deliveries.size
    user = assigns(:user)
    assert_not user.activated?
    # Try to log in before activation.
    log_in_as(user)
    assert_not is_logged_in?
    # Invalid activation token
    get edit_account_activation_path('invalid token', email: user.email)
    assert_not is_logged_in?
    # Valid token, wrong email
    get edit_account_activation_path(user.activation_token, email: 'wrong')
    assert_not is_logged_in?
    # Valid activation token
    get edit_account_activation_path(user.activation_token, email: user.email)
    assert user.reload.activated?
    follow_redirect!
    assert_template 'users/show'
    assert is_logged_in?
  end

  test 'when the user has posted a signup form ' \
       'notify fraud detection that registration has been attempted' do
    sign_up_as(
      name: 'Example User',
      email: 'user@example.com',
      password: 'password',
      password_confirmation: 'password'
    )
    assert_fraud_detection_notified_of_registration_attempted_with(
      params: {
        email: 'user@example.com'
      },
      context: {
        ip: '127.0.0.1',
        headers: {
          "Content-Length": '179',
          "Remote-Addr": '127.0.0.1',
          Version: 'HTTP/1.0',
          Host: 'www.example.com',
          Accept: 'text/xml,application/xml,application/xhtml+xml,text/html;q=0.9,text/plain;q=0.8,image/png,*/*;q=0.5',
          Cookie: true
        }
      }
    )
  end

  test 'when the user signs up and they already exist ' \
       'notify fraud detection that registration has failed' do
    FactoryBot.create(:user, :activated, email: 'duplicateuser@example.com')
    sign_up_as(
      name: 'Example User',
      email: 'duplicateuser@example.com',
      password: 'password',
      password_confirmation: 'password'
    )
    assert_fraud_detection_notified_of_registration_failed_with(
      params: {
        email: 'duplicateuser@example.com'
      },
      context: {
        ip: '127.0.0.1',
        headers: {
          "Content-Length": '188',
          "Remote-Addr": '127.0.0.1',
          Version: 'HTTP/1.0',
          Host: 'www.example.com',
          Accept: 'text/xml,application/xml,application/xhtml+xml,text/html;q=0.9,text/plain;q=0.8,image/png,*/*;q=0.5',
          Cookie: true
        }
      }
    )
  end

  test 'when the user signs up with a high likelihood of being a hacker' \
       'notify fraud detection that registration has succeeded ' \
       'and block them from signing up' do
    skip
  end

  test 'when the user signs up with a low likelihood of being a hacker' \
       'notify fraud detection that registration has succeeded ' \
       'and sign them up' do
    skip
  end

  test 'when the user signs up with a high likelihood of being a hacker' \
       'block them from signing up' do
    skip
  end

  private

  def sign_up_as(
    name:,
    email:,
    password: 'password',
    password_confirmation: password,
    likelihood_of_being_a_hacker: 0.0
  )
    VCR.use_cassette("sign_up_user_with_hacker_risk_#{likelihood_of_being_a_hacker}_with_email_#{email}") do
      get signup_path
      post users_path, params: {
        castle_request_token: "test|device:chrome_on_mac|risk:#{likelihood_of_being_a_hacker}",
        user: {
          name: name,
          email: email,
          password: password,
          password_confirmation: password_confirmation
        }
      }
    end
  end

  def assert_fraud_detection_notified_of_registration_failed_with(properties)
    signatures = WebMock::RequestRegistry.instance.requested_signatures.select do |request|
      parsed_body = JSON.parse(request.body).deep_symbolize_keys
      request.uri.to_s == 'https://api.castle.io:443/v1/filter' && parsed_body.slice(:type, :status) == ({ type: '$registration', status: '$failed' })
    end
    assert_equal 1, signatures.size, 'Expected to find one request to notify fraud detection of registration failed'
    assert_equal properties.deep_symbolize_keys, JSON.parse(signatures.first.first.body).deep_symbolize_keys.slice(*properties.keys)
  end

  def assert_fraud_detection_notified_of_registration_attempted_with(properties)
    assert_requested(:post, 'https://api.castle.io/v1/filter') do |request|
      parsed_body = JSON.parse(request.body).deep_symbolize_keys
      return false if parsed_body.slice(:type, :status) != ({ type: '$registration', status: '$attempted' })

      assert_equal parsed_body.slice(*properties.keys), properties.deep_symbolize_keys
    end
  end
end
