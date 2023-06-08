require 'test_helper'
require 'webmock/minitest'

class UsersLoginTest < ActionDispatch::IntegrationTest
  include AWSFraudDetectionAssertions
  include CloudflareAssertions

  make_my_diffs_pretty!

  def setup
    @user = users(:michael)
  end

  test 'login with valid email/invalid password' do
    get login_path
    assert_template 'sessions/new'
    user = FactoryBot.create(:user, :activated, email: 'john@example.com')
    log_in_as(user, password: 'invalid')
    assert_not is_logged_in?
    assert_template 'sessions/new'
    assert_not flash.empty?
    get root_path
    assert flash.empty?
  end

  test 'login with valid information followed by logout' do
    get login_path
    log_in_as(@user)
    assert is_logged_in?
    assert_redirected_to @user
    follow_redirect!
    assert_template 'users/show'
    assert_select 'a[href=?]', login_path, count: 0
    assert_select 'a[href=?]', logout_path
    assert_select 'a[href=?]', user_path(@user)
    delete logout_path
    assert_not is_logged_in?
    assert_redirected_to root_url
    # Simulate a user clicking logout in a second window.
    delete logout_path
    follow_redirect!
    assert_select 'a[href=?]', login_path
    assert_select 'a[href=?]', logout_path,      count: 0
    assert_select 'a[href=?]', user_path(@user), count: 0
  end

  test 'login with remembering' do
    log_in_as(@user, remember_me: '1')
    assert_not_empty cookies[:remember_token]
  end

  test 'login without remembering' do
    # Log in to set the cookie.
    log_in_as(@user, remember_me: '1')
    # Log in again and verify that the cookie is deleted.
    log_in_as(@user, remember_me: '0')
    assert_empty cookies[:remember_token]
  end

  # [^21]
  test 'prototype' do
    skip
    VCR.use_cassette('aws_prototype') do
      fraud_detector = Aws::FraudDetector::Client.new
      resp = fraud_detector.get_event_prediction(
        detector_id: 'registration',
        event_id: '12345678',
        event_type_name: 'registration',
        entities: [{ entity_type: 'user', entity_id: '1345678' }],
        event_timestamp: 2.minutes.ago.iso8601,
        event_variables: {
          email: 'safe@example.org',
          ip_address: '1.2.3.4',
          registered_at: 2.minutes.ago.iso8601
        }
      )
      throw resp
    end
  end

  # [^21]
  test 'aws send event' do
    skip
    VCR.use_cassette('aws_send_event') do
      fraud_detector = Aws::FraudDetector::Client.new
      resp = fraud_detector.send_event(
        event_id: '802454d3-f7d8-482d-97e8-c4b6db9a0428',
        event_type_name: 'registration',
        event_timestamp: 2.minutes.ago.iso8601,
        event_variables: {
          email: 'safe@example.org',
          ip_address: '1.2.3.4'
        },
        assigned_label: 'legitimate',
        label_timestamp: 2.minutes.ago.iso8601,
        entities: [{ entity_type: 'user', entity_id: '12345' }]
      )
    end
  end

  # Genuine users
  test 'notifies fraud detection when a genuinue user has failed login ' \
       'so that the fraud detection learns about hackers' do
    user = FactoryBot.create(:user, :activated, email: 'safe@example.org')
    log_in_as(
      user,
      password: 'invalid',
      matching_policy: :allow
    )
    assert_fraud_detection_notified_of_failed_login_with(
      event_type_name: 'registration',
      event_variables: {
        email: 'safe@example.org',
        ip_address: '127.0.0.1'
      },
      assigned_label: 'legitimate',
      entities: [{ entity_type: 'user', entity_id: 'safe@example.org' }]
    )
  end

  test "when user isn't activated yet " \
        "don't send their details to be risk assessed" \
        "as they can't log in yet" do
          skip
    inactive_user = FactoryBot.create(
      :user,
      name: 'Joe Bloggs',
      email: 'joeinactive@example.org',
      activated: false,
      activated_at: nil
    )
    log_in_as(
      inactive_user,
      matching_policy: :allow
    )
    assert_fraud_detection_not_called
  end

  test 'when the user has a low likelihood of being a hacker' \
       'allow them to log in' do
        skip
    log_in_as(
      @user,
      matching_policy: :allow
    )
    assert is_logged_in?, 'Expected to be logged in'
    assert response.status == 302, 'Expected 302, got ' + response.status.to_s
  end

  test "sends the user's details to be risk assessed " \
       'so that we can accurately detect hackers' do
        skip
    user = FactoryBot.create(
      :user,
      name: 'Joe Bloggs',
      email: 'joe@example.org',
      activated: true,
      activated_at: Time.zone.parse('2012-12-02 00:30:08.276 UTC')
    )
    log_in_as(
      user,
      matching_policy: :allow
    )
    assert_fraud_detection_notified_of_login_succeeded_with(
      user: {
        id: user.id.to_s,
        registered_at: '2012-12-02T00:30:08Z',
        email: 'joe@example.org',
        name: 'Joe Bloggs'
      },
      context: {
        ip: '127.0.0.1',
        headers: {
          "Remote-Addr": '127.0.0.1',
          Version: 'HTTP/1.0',
          Host: 'www.example.com',
          Accept: 'text/xml,application/xml,application/xhtml+xml,text/html;q=0.9,text/plain;q=0.8,image/png,*/*;q=0.5',
          Cookie: true
        }
      }
    )
  end

  test 'notifies fraud detection of attempted valid login ' \
       'so that the fraud detection has more information to learn from' do
        skip
    log_in_as(
      @user,
      matching_policy: :allow
    )
    assert_fraud_detection_notified_of_login_attempted_with(
      params: {
        email: @user.email
      },
      context: {
        ip: '127.0.0.1',
        headers: {
          "Remote-Addr": '127.0.0.1',
          Version: 'HTTP/1.0',
          Host: 'www.example.com',
          Accept: 'text/xml,application/xml,application/xhtml+xml,text/html;q=0.9,text/plain;q=0.8,image/png,*/*;q=0.5',
          Cookie: true
        }
      }
    )
  end

  # Possible hackers
  test 'when the user has a medium likelihood of being a hacker' \
       'allow them to log in' do
        skip
    log_in_as(
      @user,
      matching_policy: :challenge
    )
    assert is_logged_in?, 'Expected to be logged in'
    assert response.status == 302, 'Expected 302, got ' + response.status.to_s
  end

  test 'when the user has a medium likelihood of being a hacker' \
       'challenge them the next time they log in' do
        skip
    log_in_as(
      @user,
      matching_policy: :challenge
    )
    assert_user_challenged(ip: '127.0.0.1')
  end

  # Definite hackers
  test 'when the user has a high likelihood of being a hacker' \
       'block them from logging in' do
        skip
    log_in_as(
      @user,
      matching_policy: :deny
    )
    assert_not is_logged_in?, 'Expected not to be logged in'
    assert response.status == 500, 'Expected 500, got ' + response.status.to_s
  end

  test 'when a user with valid password has a high likelihood of being a hacker' \
       'sends the users details to risk assessment ' \
       'so that other hackers with valid passwords are recognised' do
        skip
    log_in_as(
      @user,
      matching_policy: :deny
    )
    assert_fraud_detection_notified_of_login_succeeded_with(
      user: {
        id: @user.id.to_s,
        registered_at: @user.activated_at.iso8601,
        email: @user.email,
        name: @user.name
      },
      context: {
        ip: '127.0.0.1',
        headers: {
          "Remote-Addr": '127.0.0.1',
          Version: 'HTTP/1.0',
          Host: 'www.example.com',
          Accept: 'text/xml,application/xml,application/xhtml+xml,text/html;q=0.9,text/plain;q=0.8,image/png,*/*;q=0.5',
          Cookie: true
        }
      }
    )
  end

  test 'when a user has a high likelihood of being a hacker ' \
       'block their IP address' do
        skip
    log_in_as(
      @user,
      matching_policy: :deny
    )
    assert_user_blocked(ip: '127.0.0.1')
  end

  test 'when the hacker has the wrong password ' \
       "render new and don't log them in" do
        skip
    user = FactoryBot.create(:user, :activated, email: 'jane@example.org')
    log_in_as(
      user,
      password: 'invalid',
      matching_policy: :deny
    )
    assert_not is_logged_in?, 'Expected to be logged out'
    assert response.status == 200, 'Expected 200, got ' + response.status.to_s
  end
end
