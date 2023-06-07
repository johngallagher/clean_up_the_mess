module Protectable
  extend ActiveSupport::Concern

  # [^3]
  class RiskPolicy
    def initialize(policy)
      @policy = policy[:action]
    end

    def deny?
      @policy == 'deny'
    end

    def challenge?
      @policy == 'challenge'
    end

    def allow?
      @policy == 'allow'
    end
  end

  class PolicyAction
    def initialize(policy:)
      @policy = policy
    end

    def on_deny
      yield if @policy.deny?
    end

    def on_challenge
      yield if @policy.challenge?
    end
  end

  module FraudDetection
    class CastlePolicyEvaluator
      # [^19]
      EVENT_TO_CASTLE_EVENT_MAPPINGS = {
        # event_name => [type, status, name] (we use name for custom events)
        'login.succeeded' => ['$login', '$succeeded', ''],
        'login.attempted' => ['$login', '$attempted', ''],
        'login.failed' => ['$login', '$failed', ''],
        'registration.succeeded' => ['$registration', '$succeeded', ''],
        'registration.attempted' => ['$registration', '$attempted', ''],
        'registration.failed' => ['$registration', '$failed', ''],
        'micropost.created' => ['$custom', '', 'Micropost created']
      }

      def evaluate_policy(user:, event:, request:)
        type, status, name = EVENT_TO_CASTLE_EVENT_MAPPINGS.fetch(event)
        castle = ::Castle::Client.new
        token = request.params[:castle_request_token]
        context = Castle::Context::Prepare.call(request)
        response = castle.risk(
          type: type,
          status: status,
          name: name,
          request_token: token,
          user: {
            id: user.id.to_s,
            email: user.email,
            name: user.name
          }.merge(user.activated? ? { registered_at: user.activated_at.iso8601 } : {}),
          context: {
            ip: context[:ip],
            headers: context[:headers]
          }.compact_blank
        )
        RiskPolicy.new(response[:policy])
      end

      def notify_fraud_detection_system_of(event, request:)
        type, status, = EVENT_TO_CASTLE_EVENT_MAPPINGS.fetch(event)
        email = request.params[:user][:email] if type == '$registration'
        email = request.params[:session][:email] if type == '$login'

        castle = ::Castle::Client.new
        token = request.params[:castle_request_token]
        context = Castle::Context::Prepare.call(request)
        castle.filter(
          type: type,
          status: status,
          request_token: token,
          params: {
            email: email
          },
          context: {
            ip: context[:ip],
            headers: context[:headers]
          }
        )
      end
    end
  end

  included do
    def protect_from_bad_actors(user:, event:, request:)
      policy = FraudDetection::CastlePolicyEvaluator.new.evaluate_policy(
        user: user,
        event: event,
        request: request
      )
      block_or_challenge_bad_actors(policy: policy, request: request)
    end

    def block_or_challenge_bad_actors(policy:, request:)
      action = PolicyAction.new(policy: policy)
      action.on_deny { block_ip_address(request.remote_ip) }
      action.on_challenge { challenge_ip_address(request.remote_ip) }
      action
    end

    def notify_fraud_detection_system_of(event)
      FraudDetection::CastlePolicyEvaluator.new.notify_fraud_detection_system_of(
        event,
        request: request
      )
    end

    # firewall, IP address
    def challenge_ip_address(ip)
      create_firewall_rule(ip, mode: 'challenge')
    end

    # firewall, IP address
    def block_ip_address(ip)
      create_firewall_rule(ip, mode: 'block')
    end

    # Cloudflare, firewall
    def create_firewall_rule(ip, mode:)
      require 'uri'
      require 'net/http'
      require 'openssl'

      url = URI('https://api.cloudflare.com/client/v4/accounts/a4bedc9e66fe2e421c76b068531a75a2/firewall/access_rules/rules')

      http = Net::HTTP.new(url.host, url.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE

      request = Net::HTTP::Post.new(url)
      request['Content-Type'] = 'application/json'
      request['X-Auth-Email'] = ENV.fetch('CLOUDFLARE_API_EMAIL')
      request['X-Auth-Key'] = ENV.fetch('CLOUDFLARE_API_TOKEN')
      request.body = JSON.generate({ configuration: { target: 'ip', value: ip }, mode: mode })

      http.request(request)
    end
  end
end
