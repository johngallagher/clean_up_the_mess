module CloudflareAssertions
  def assert_user_blocked(ip:)
    assert_requested(
      :post,
      'https://api.cloudflare.com/client/v4/accounts/a4bedc9e66fe2e421c76b068531a75a2/firewall/access_rules/rules',
      body: JSON.generate({ configuration: { target: 'ip', value: ip }, mode: 'block' })
    )
  end

  def assert_user_challenged(ip:)
    assert_requested(
      :post,
      'https://api.cloudflare.com/client/v4/accounts/a4bedc9e66fe2e421c76b068531a75a2/firewall/access_rules/rules',
      body: JSON.generate({ configuration: { target: 'ip', value: ip }, mode: 'challenge' })
    )
  end

  def assert_not_blocked_or_challenged
    assert_not_requested(
      :post,
      'https://api.cloudflare.com/client/v4/accounts/a4bedc9e66fe2e421c76b068531a75a2/firewall/access_rules/rules'
    )
  end
end
