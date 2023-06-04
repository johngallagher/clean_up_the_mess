require 'test_helper'

class MicropostsInterfaceTest < ActionDispatch::IntegrationTest
  def setup
    @user = users(:michael)
  end

  test 'micropost interface' do
    log_in_as(@user)
    get root_path
    assert_select 'div.pagination'
    # Invalid submission
    assert_no_difference 'Micropost.count' do
      create_micropost('')
    end
    assert_select 'div#error_explanation'
    assert_select 'a[href=?]', '/?page=2' # Correct pagination link
    # Valid submission
    content = 'This micropost really ties the room together'
    assert_difference 'Micropost.count', 1 do
      create_micropost(content)
    end
    assert_redirected_to root_url
    follow_redirect!
    assert_match content, response.body
    # Delete post
    assert_select 'a', text: 'delete'
    first_micropost = @user.microposts.paginate(page: 1).first
    assert_difference 'Micropost.count', -1 do
      delete micropost_path(first_micropost)
    end
    # Visit different user (no delete links)
    get user_path(users(:archer))
    assert_select 'a', text: 'delete', count: 0
  end

  test "prevents microposts from being created by hackers" do
    log_in_as(@user)
    assert_no_difference 'Micropost.count' do
      create_micropost('Content', likelihood_of_being_a_hacker: 1.0)
    end
  end

  test "challenges when microposts are being created by a hacker" do
    log_in_as(@user)
    create_micropost('Content', likelihood_of_being_a_hacker: 1.0)
    assert_user_challenged(ip: '127.0.0.1')
  end

  private

  def create_micropost(content, likelihood_of_being_a_hacker: 0.0)
    VCR.use_cassette("create_micropost_with_hacker_risk_#{likelihood_of_being_a_hacker}") do
      post microposts_path, params: {
        castle_request_token: "test|device:chrome_on_mac|risk:#{likelihood_of_being_a_hacker}",
        micropost: { content: content }
      }
    end
  end

  def assert_user_challenged(ip:)
    assert_requested(
      :post,
      'https://api.cloudflare.com/client/v4/accounts/a4bedc9e66fe2e421c76b068531a75a2/firewall/access_rules/rules',
      body: JSON.generate({ configuration: { target: 'ip', value: ip }, mode: 'challenge' })
    )
  end
end
