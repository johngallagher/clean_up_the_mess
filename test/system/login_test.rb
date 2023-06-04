require 'application_system_test_case'

class LoginTest < ApplicationSystemTestCase
  test "attempting login shows the user's welcome page" do
    user = FactoryBot.create(:user, name: 'Joe Bloggs')
    log_in_as(user)
    assert_on_welcome_page_for(user)
  end
end
