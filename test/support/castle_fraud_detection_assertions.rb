module CastleFraudDetectionAssertions
  def assert_fraud_detection_notified_of_login_succeeded_with(properties)
    assert_requested(:post, 'https://api.castle.io/v1/risk') do |request|
      parsed_body = JSON.parse(request.body).deep_symbolize_keys
      return false if parsed_body.slice(:type, :status) != ({ type: '$login', status: '$succeeded' })

      assert_equal remove_content_length(parsed_body.slice(*properties.keys)),
                   remove_content_length(properties.deep_symbolize_keys)
    end
  end

  def assert_fraud_detection_notified_of_failed_login_with(properties)
    assert_requested(:post, 'https://api.castle.io/v1/filter') do |request|
      parsed_body = JSON.parse(request.body).deep_symbolize_keys
      return false if parsed_body.slice(:type, :status) != ({ type: '$login', status: '$failed' })

      assert_equal remove_content_length(parsed_body.slice(*properties.keys)),
                   remove_content_length(properties.deep_symbolize_keys)
    end
  end

  def assert_fraud_detection_notified_of_login_attempted_with(properties)
    assert_requested(:post, 'https://api.castle.io/v1/filter') do |request|
      parsed_body = JSON.parse(request.body).deep_symbolize_keys
      return false if parsed_body.slice(:type, :status) != ({ type: '$login', status: '$attempted' })

      assert_equal remove_content_length(parsed_body.slice(*properties.keys)),
                   remove_content_length(properties.deep_symbolize_keys)
    end
  end

  def assert_fraud_detection_notified_of_registration_failed_with(properties)
    signatures = WebMock::RequestRegistry.instance.requested_signatures.select do |request|
      uri_matches = request.uri.to_s == 'https://api.castle.io:443/v1/filter'
      parsed_body = JSON.parse(request.body).deep_symbolize_keys
      body_matches = parsed_body.slice(:type, :status) == ({ type: '$registration', status: '$failed' })
      uri_matches && body_matches
    end
    actual_signature = JSON.parse(signatures.first.first.body).deep_symbolize_keys.slice(*properties.keys)
    assert_equal remove_content_length(properties.deep_symbolize_keys), remove_content_length(actual_signature)
    assert_equal 1, signatures.size, 'Expected to find one request to notify fraud detection of registration failed'
  end

  def assert_fraud_detection_notified_of_registration_succeeded_with(properties)
    signatures = WebMock::RequestRegistry.instance.requested_signatures.select do |request|
      uri_matches = request.uri.to_s == 'https://api.castle.io:443/v1/risk'
      parsed_body = JSON.parse(request.body).deep_symbolize_keys
      body_matches = parsed_body.slice(:type, :status) == ({ type: '$registration', status: '$succeeded' })
      uri_matches && body_matches
    end
    actual_signature = JSON.parse(signatures.first.first.body).deep_symbolize_keys.slice(*properties.keys)
    assert_equal remove_content_length(properties.deep_symbolize_keys), remove_content_length(actual_signature)
    assert_equal 1, signatures.size, 'Expected to find one request to notify fraud detection of registration succeeded'
  end

  def assert_fraud_detection_notified_of_registration_attempted_with(properties)
    assert_requested(:post, 'https://api.castle.io/v1/filter') do |request|
      parsed_body = JSON.parse(request.body).deep_symbolize_keys
      return false if parsed_body.slice(:type, :status) != ({ type: '$registration', status: '$attempted' })

      assert_equal remove_content_length(properties.deep_symbolize_keys),
                   remove_content_length(parsed_body.slice(*properties.keys))
    end
  end

  def remove_content_length(hash)
    hash.deep_merge(context: { headers: { 'Content-Length': '' } }).compact_blank
  end

  def assert_fraud_detection_not_called
    assert_not_requested(:post, 'https://api.castle.io/v1/risk')
  end

  def remove_content_length(hash)
    hash.deep_merge(context: { headers: { 'Content-Length': '' } }).compact_blank
  end
end
