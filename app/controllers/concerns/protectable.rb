module Protectable
  extend ActiveSupport::Concern

  # [^3]
  class RiskScore
    def initialize(score)
      @score = score
    end

    def low?
      @score < 0.6
    end

    def medium?
      @score >= 0.6 && @score < 0.8
    end

    def high?
      @score >= 0.8
    end
  end

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

  included do
    def assess_risk_of_a_bad_actor_logging_in(user:)
      response = fetch_hacker_likelihood(user: user, type: '$login', status: '$succeeded')
      RiskScore.new(response[:risk])
    end
      
    def assess_risk_of_a_bad_actor_registering(user:)
      response = fetch_hacker_likelihood(user: user, type: '$registration', status: '$succeeded')
      RiskScore.new(response[:risk])
    end

    def assess_risk_of_a_bad_actor_creating_a_micropost(user:)
      response = fetch_hacker_likelihood(user: user, type: '$custom', name: 'Created a micropost')
      RiskScore.new(response[:risk])
    end

    def match_actor_against_policy_for_logging_in(user:)
      response = fetch_hacker_likelihood(user: user, type: '$login', status: '$succeeded')
      RiskPolicy.new(response[:policy])
    end

    def match_actor_against_policy_for_registration(user:)
      response = fetch_hacker_likelihood(user: user, type: '$registration', status: '$succeeded')
      RiskPolicy.new(response[:policy])
    end

    def match_actor_against_policy_for_creating_a_micropost(user:)
      response = fetch_hacker_likelihood(user: user, type: '$custom', name: 'Created a micropost')
      RiskPolicy.new(response[:policy])
    end

    def protect_creating_a_micropost_from_bad_actors(user:, request:)
      policy =  match_actor_against_policy_for_creating_a_micropost(user: user)
      action = PolicyAction.new(policy: policy)
      action.on_deny { block_ip_address(request.remote_ip) }
      action.on_challenge { challenge_ip_address(request.remote_ip) }
      action
    end

    def fetch_hacker_likelihood(user:, type:, status: '', name: '')
      castle = ::Castle::Client.new
      token = params[:castle_request_token]
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
      response
    end

    def notify_fraud_detection_system_of_registration_failed
      notify_fraud_detection_system_of(type: '$registration', status: '$failed')
    end

    def notify_fraud_detection_system_of_registration_attempted
      notify_fraud_detection_system_of(type: '$registration', status: '$attempted')
    end

    def notify_fraud_detection_system_of_login_attempted
      notify_fraud_detection_system_of(type: '$login', status: '$attempted')
    end

    def notify_fraud_detection_system_of_failed_login_attempt
      notify_fraud_detection_system_of(type: '$login', status: '$failed')
    end

    def notify_fraud_detection_system_of(type:, status:)
      email = user_params[:email] if type == '$registration'
      email = params[:session][:email] if type == '$login'

      castle = ::Castle::Client.new
      token = params[:castle_request_token]
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

    def challenge_ip_address(ip)
      create_firewall_rule(ip, mode: 'challenge')
    end

    def block_ip_address(ip)
      create_firewall_rule(ip, mode: 'block')
    end

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
