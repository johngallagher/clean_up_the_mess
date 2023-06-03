require "application_system_test_case"

class LoginTest < ApplicationSystemTestCase
  test "attempting login when user is not activated " \
       "tells the user to activate their account first" do
    user = FactoryBot.create :user, name: "Joe Bloggs", email: 'joe@example.org', password: 'password'
    visit login_path

    fill_in 'Email', with: 'joe@example.org'
    fill_in 'Password', with: 'password'
    click_button 'Log in'

    assert_text "Account not activated"
  end
end
