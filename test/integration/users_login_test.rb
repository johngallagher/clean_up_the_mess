require 'test_helper'

class UsersLoginTest < ActionDispatch::IntegrationTest
  def setup
    @user = users(:michael)
    @user_with_invalid_password = users(:with_invalid_password)
  end

  test 'login with valid email/invalid password' do
    get login_path
    assert_template 'sessions/new'
    log_in_as(@user, password: 'invalid')
    assert_not is_logged_in?
    assert_template 'sessions/new'
    assert_not flash.empty?
    get root_path
    assert flash.empty?
  end

  test 'login with valid information followed by logout' do
    get login_path
    log_in_as(@user, password: 'password')
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

  test 'when the user has a high likelihood of being a hacker' \
       'block them from logging in' do
    log_in_as(@user, likelihood_of_being_a_hacker: 1.0)
    assert_not is_logged_in?, 'Expected not to be logged in'
    assert response.status == 500, 'Expected 500, got ' + response.status.to_s
  end

  test 'when the user has a medium-high likelihood of being a hacker' \
       'block them from logging in' do
    log_in_as(@user, likelihood_of_being_a_hacker: 0.9)
    assert_not is_logged_in?, 'Expected to be logged out'
    assert response.status == 500, 'Expected 500, got ' + response.status.to_s
  end

  test 'when the user has a low likelihood of being a hacker' \
       'allow them to log in' do
    log_in_as(@user, likelihood_of_being_a_hacker: 0.0)
    assert is_logged_in?, 'Expected to be logged in'
    assert response.status == 302, 'Expected 302, got ' + response.status.to_s
  end

  test "when the hacker has the wrong password " \
       "render new and don't log them in" do
    log_in_as(@user_with_invalid_password, likelihood_of_being_a_hacker: 1.0)
    assert_not is_logged_in?, 'Expected to be logged out'
    assert response.status == 200, 'Expected 200, got ' + response.status.to_s
  end
end
