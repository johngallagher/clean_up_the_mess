require 'application_system_test_case'

class SignupTest < ApplicationSystemTestCase
  test 'signing up a user shows welcome page' do
    after_signing_up_with(
      name: 'Example User',
      email: 'user@example.com',
      password: 'password',
      password_confirmation: 'password'
    ) do
      assert_on_welcome_page
    end
  end

  private

  def after_signing_up_with(name:, email:, password:, password_confirmation:)
    VCR.use_cassette('signup_with_low_risk_user') do
      visit signup_path

      fill_in 'Name', with: name
      fill_in 'Email', with: email
      fill_in 'Password', with: password
      fill_in 'Confirmation', with: password_confirmation
      click_button 'Create my account'

      yield
    end
  end

  def assert_on_welcome_page
    assert_text "This is the home page for the Ruby on Rails Tutorial sample application"
  end
end
