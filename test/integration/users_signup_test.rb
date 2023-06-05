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

  # Genuine users
  test 'when the user signs up with a low likelihood of being a hacker at lower bounds ' \
       'sign them up and redirect them' \
       'and do not block them' do
    sign_up_as(
      likelihood_of_being_a_hacker: 0.0,
      matching_policy: :allow
    )
    assert_redirected_to root_url
    assert_equal 1, User.where(email: 'user@example.com').count
    assert_not_blocked_or_challenged
  end

  test 'when the user signs up with a low likelihood of being a hacker at upper bounds' \
       'sign them up and redirect them' \
       'and do not block them' do
    sign_up_as(
      likelihood_of_being_a_hacker: 0.59,
      matching_policy: :allow
    )
    assert_redirected_to root_url
    assert_equal 1, User.where(email: 'user@example.com').count
    assert_not_blocked_or_challenged
  end

  test 'when the user signs up with a low likelihood of being a hacker' \
       'notify fraud detection that registration has succeeded ' do
    sign_up_as(
      likelihood_of_being_a_hacker: 0.0,
      matching_policy: :allow
    )
    assert_fraud_detection_notified_of_registration_succeeded_with(
      user: {
        id: User.find_by(email: 'user@example.com').id.to_s,
        email: 'user@example.com',
        name: 'Example User'
      },
      context: expected_request_context
    )
  end

  test 'when the user has posted a signup form ' \
       'notify fraud detection that registration has been attempted' do
    sign_up_as(
      name: 'Example User',
      email: 'user@example.com',
      password: 'password',
      password_confirmation: 'password',
      likelihood_of_being_a_hacker: 0.0,
      matching_policy: :allow
    )
    assert_fraud_detection_notified_of_registration_attempted_with(
      params: { email: 'user@example.com' },
      context: expected_request_context
    )
  end

  test 'when the user signs up and they already exist ' \
       'notify fraud detection that registration has failed' do
    FactoryBot.create(:user, :activated, email: 'duplicateuser@example.com')
    sign_up_as(
      name: 'Example User',
      email: 'duplicateuser@example.com',
      password: 'password',
      password_confirmation: 'password',
      likelihood_of_being_a_hacker: 0.0,
      matching_policy: :allow
    )
    assert_fraud_detection_notified_of_registration_failed_with(
      params: { email: 'duplicateuser@example.com' },
      context: expected_request_context
    )
  end

  # Possible hackers
  test 'when the user signs up with a medium likelihood of being a hacker at lower bounds ' \
       'treat them as a risk' do
    sign_up_as(likelihood_of_being_a_hacker: 0.6, matching_policy: :challenge)
    assert_user_challenged(ip: '127.0.0.1')
    assert_redirected_to root_url
    assert_equal 1, User.where(email: 'user@example.com').count
  end

  test 'when the user signs up with a medium likelihood of being a hacker upper bounds ' \
       'treat them as a risk' do
    sign_up_as(likelihood_of_being_a_hacker: 0.79, matching_policy: :challenge)
    assert_user_challenged(ip: '127.0.0.1')
    assert_redirected_to root_url
    assert_equal 1, User.where(email: 'user@example.com').count
  end

  # Hackers
  test 'when the user signs up with a high likelihood of being a hacker lower bounds ' \
       'treat them as a bad actor but create the acccount' do
    sign_up_as(likelihood_of_being_a_hacker: 0.8, matching_policy: :deny)
    assert_user_blocked(ip: '127.0.0.1')
    assert_template 'users/new'
    assert_equal 1, User.where(email: 'user@example.com').count
  end

  test 'when the user signs up with a high likelihood of being a hacker upper bounds ' \
       'treat them as a bad actor but create the acccount' do
    sign_up_as(likelihood_of_being_a_hacker: 1.0, matching_policy: :deny)
    assert_user_blocked(ip: '127.0.0.1')
    assert_template 'users/new'
    assert_equal 1, User.where(email: 'user@example.com').count
  end

  test 'when the user signs up with a high likelihood of being a hacker' \
       'notify fraud detection that registration has succeeded ' do
    sign_up_as(likelihood_of_being_a_hacker: 1.0, matching_policy: :deny)
    assert_fraud_detection_notified_of_registration_succeeded_with(
      user: {
        id: User.find_by(email: 'user@example.com').id.to_s,
        email: 'user@example.com',
        name: 'Example User'
      },
      context: expected_request_context
    )
  end

  private

  def sign_up_as(
    name: 'Example User',
    email: 'user@example.com',
    password: 'password',
    password_confirmation: password,
    likelihood_of_being_a_hacker: 0.0,
    matching_policy: :allow
  )
    VCR.use_cassette("sign_up_user_with_hacker_risk_#{likelihood_of_being_a_hacker}_policy_action_#{matching_policy}_with_email_#{email}") do
      get signup_path
      post users_path, params: {
        castle_request_token: "test|device:chrome_on_mac|risk:#{likelihood_of_being_a_hacker}|policy.action:#{matching_policy}",
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
      uri_matches = request.uri.to_s == 'https://api.castle.io:443/v1/filter'
      parsed_body = JSON.parse(request.body).deep_symbolize_keys
      body_matches = parsed_body.slice(:type, :status) == ({ type: '$registration', status: '$failed' })
      uri_matches && body_matches
    end
    actual_signature = JSON.parse(signatures.first.first.body).deep_symbolize_keys.slice(*properties.keys)
    assert_equal remove_content_length(properties.deep_symbolize_keys), remove_content_length(actual_signature)
    assert_equal 1, signatures.size, 'Expected to find one request to notify fraud detection of registration failed'
  end

  def assert_fraud_detection_notified_of_registration_succeeded_with(properties)
    signatures = WebMock::RequestRegistry.instance.requested_signatures.select do |request|
      uri_matches = request.uri.to_s == 'https://api.castle.io:443/v1/risk'
      parsed_body = JSON.parse(request.body).deep_symbolize_keys
      body_matches = parsed_body.slice(:type, :status) == ({ type: '$registration', status: '$succeeded' })
      uri_matches && body_matches
    end
    actual_signature = JSON.parse(signatures.first.first.body).deep_symbolize_keys.slice(*properties.keys)
    assert_equal remove_content_length(properties.deep_symbolize_keys), remove_content_length(actual_signature)
    assert_equal 1, signatures.size, 'Expected to find one request to notify fraud detection of registration succeeded'
  end

  def assert_fraud_detection_notified_of_registration_attempted_with(properties)
    assert_requested(:post, 'https://api.castle.io/v1/filter') do |request|
      parsed_body = JSON.parse(request.body).deep_symbolize_keys
      return false if parsed_body.slice(:type, :status) != ({ type: '$registration', status: '$attempted' })

      assert_equal remove_content_length(properties.deep_symbolize_keys),
                   remove_content_length(parsed_body.slice(*properties.keys))
    end
  end

  def remove_content_length(hash)
    hash.deep_merge(context: { headers: { 'Content-Length': '' } }).compact_blank
  end

  def assert_user_blocked(ip:)
    assert_requested(
      :post,
      'https://api.cloudflare.com/client/v4/accounts/a4bedc9e66fe2e421c76b068531a75a2/firewall/access_rules/rules',
      body: JSON.generate({ configuration: { target: 'ip', value: ip }, mode: 'block' })
    )
  end

  def assert_user_challenged(ip:)
    assert_requested(
      :post,
      'https://api.cloudflare.com/client/v4/accounts/a4bedc9e66fe2e421c76b068531a75a2/firewall/access_rules/rules',
      body: JSON.generate({ configuration: { target: 'ip', value: ip }, mode: 'challenge' })
    )
  end

  def assert_not_blocked_or_challenged
    assert_not_requested(
      :post,
      'https://api.cloudflare.com/client/v4/accounts/a4bedc9e66fe2e421c76b068531a75a2/firewall/access_rules/rules'
    )
  end

  def expected_request_context
    {
      ip: '127.0.0.1',
      headers: {
        "Remote-Addr": '127.0.0.1',
        Version: 'HTTP/1.0',
        Host: 'www.example.com',
        Accept: 'text/xml,application/xml,application/xhtml+xml,text/html;q=0.9,text/plain;q=0.8,image/png,*/*;q=0.5',
        Cookie: true
      }
    }
  end
end
