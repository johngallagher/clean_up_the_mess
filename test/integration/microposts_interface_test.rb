require 'test_helper'

class MicropostsInterfaceTest < ActionDispatch::IntegrationTest
  include CloudflareAssertions

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

  # Possible hackers
  test 'allows microposts to be created by possible hackers' do
    log_in_as(@user)
    assert_difference 'Micropost.count', 1 do
      create_micropost('Content', matching_policy: :challenge)
    end
  end

  test 'challenges when microposts are being created by a possible hacker' do
    log_in_as(@user)
    create_micropost('Content', matching_policy: :challenge)
    assert_user_challenged(ip: '127.0.0.1')
  end

  # Hackers
  test 'prevents microposts from being created by hackers' do
    log_in_as(@user)
    assert_no_difference 'Micropost.count' do
      create_micropost('Content', matching_policy: :deny)
    end
  end

  test 'challenges when microposts are being created by a hacker' do
    log_in_as(@user)
    create_micropost('Content', matching_policy: :deny)
    assert_user_blocked(ip: '127.0.0.1')
  end

  private

  def create_micropost(content, matching_policy: :allow)
    VCR.use_cassette("create_micropost_with_policy_#{matching_policy}") do
      post microposts_path, params: {
        castle_request_token: "test|device:chrome_on_mac|policy.action:#{matching_policy}",
        micropost: { content: content }
      }
    end
  end
end
