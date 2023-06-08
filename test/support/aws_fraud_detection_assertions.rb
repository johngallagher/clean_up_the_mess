module AWSFraudDetectionAssertions
  def assert_fraud_detection_notified_of_login_succeeded_with(properties)
    assert_requested(:post, 'https://frauddetector.us-east-1.amazonaws.com') do |request|
      parsed_body = JSON.parse(request.body).deep_transform_keys { |key| key.to_s.underscore.to_sym }
      assert_equal parsed_body.slice(*properties.keys),
                   properties.deep_symbolize_keys
    end
  end

  def assert_fraud_detection_notified_of_failed_login_with(properties)
    assert_requested(:post, 'https://frauddetector.us-east-1.amazonaws.com') do |request|
      parsed_body = JSON.parse(request.body).deep_transform_keys { |key| key.to_s.underscore.to_sym }
      assert_equal parsed_body.slice(*properties.keys),
                   properties.deep_symbolize_keys
    end
  end

  def assert_fraud_detection_notified_of_login_attempted_with(properties)
    assert_requested(:post, 'https://frauddetector.us-east-1.amazonaws.com') do |request|
      parsed_body = JSON.parse(request.body).deep_transform_keys { |key| key.to_s.underscore.to_sym }
      assert_equal parsed_body.slice(*properties.keys),
                   properties.deep_symbolize_keys
    end
  end

  def assert_fraud_detection_notified_of_registration_attempted_with(properties)
    assert_requested(:post, 'https://frauddetector.us-east-1.amazonaws.com') do |request|
      parsed_body = JSON.parse(request.body).deep_transform_keys { |key| key.to_s.underscore.to_sym }
      assert_equal parsed_body.slice(*properties.keys),
                   properties.deep_symbolize_keys
    end
  end

  def assert_fraud_detection_notified_of_registration_failed_with(properties)
    signatures = WebMock::RequestRegistry.instance.requested_signatures.select do |request|
      uri_matches = request.uri.to_s == 'https://frauddetector.us-east-1.amazonaws.com'
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
      uri_matches = request.uri.to_s == 'https://frauddetector.us-east-1.amazonaws.com'
      parsed_body = JSON.parse(request.body).deep_symbolize_keys
      body_matches = parsed_body.slice(:type, :status) == ({ type: '$registration', status: '$succeeded' })
      uri_matches && body_matches
    end
    actual_signature = JSON.parse(signatures.first.first.body).deep_symbolize_keys.slice(*properties.keys)
    assert_equal remove_content_length(properties.deep_symbolize_keys), remove_content_length(actual_signature)
    assert_equal 1, signatures.size, 'Expected to find one request to notify fraud detection of registration succeeded'
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
