require 'application_system_test_case'

class LoginTest < ApplicationSystemTestCase
  test "logging in a user shows the user's welcome page" do
    user = FactoryBot.create(:user, :activated, name: 'Joe Bloggs')
    whilst_user_logged_in(user) do
      assert_on_welcome_page_for(user)
    end
  end

  private

  def whilst_user_logged_in(user)
    VCR.use_cassette('login_with_low_risk_user') do
      visit login_path

      fill_in 'Email', with: user.email
      fill_in 'Password', with: user.password
      click_button 'Log in'

      yield
    end
  end

  def assert_on_welcome_page_for(user)
    assert_text user.name
  end
end
