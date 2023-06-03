require "application_system_test_case"

class LoginTest < ApplicationSystemTestCase
  test "attempting login when user is activated " \
       "shows the user's welcome page" do
    user = FactoryBot.create :user, name: "Joe Bloggs", email: 'joe@example.org', password: 'password', activated: true, activated_at: Time.zone.now
    visit login_path

    fill_in 'Email', with: 'joe@example.org'
    fill_in 'Password', with: 'password'
    click_button 'Log in'

    assert_text "Joe Bloggs"
  end
end
