require "application_system_test_case"

class LoginTest < ApplicationSystemTestCase
  test "logging in" do
    user = FactoryBot.create :user, name: "Joe Bloggs", email: 'joe@example.org', password: 'password'
    visit login_path

    fill_in 'Email', with: 'joe@example.org'
    fill_in 'Password', with: 'password'
    click_button 'Log in'

    assert_text "Joe Bloggs"
  end
end
