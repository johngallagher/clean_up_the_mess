module Protectable
  extend ActiveSupport::Concern

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

  included do
    def assess_risk_of_a_bad_actor_logging_in(user:)
      score = fetch_hacker_likelihood(user: user, type: '$login', status: '$succeeded')
      RiskScore.new(score)
    end

    def notify_fraud_detection_system_of_registration_failed
      castle = ::Castle::Client.new
      token = params[:castle_request_token]
      context = Castle::Context::Prepare.call(request)
      castle.filter(
        type: '$registration',
        status: '$failed',
        request_token: token,
        params: {
          email: user_params[:email]
        },
        context: {
          ip: context[:ip],
          headers: context[:headers]
        }
      )
    end

    def notify_fraud_detection_system_of_registration_attempted
      castle = ::Castle::Client.new
      token = params[:castle_request_token]
      context = Castle::Context::Prepare.call(request)
      castle.filter(
        type: '$registration',
        status: '$attempted',
        request_token: token,
        params: {
          email: user_params[:email]
        },
        context: {
          ip: context[:ip],
          headers: context[:headers]
        }
      )
    end

    def notify_fraud_detection_system_of_login_attempted
      castle = ::Castle::Client.new
      token = params[:castle_request_token]
      context = Castle::Context::Prepare.call(request)
      castle.filter(
        type: '$login',
        status: '$attempted',
        request_token: token,
        params: {
          email: params[:session][:email]
        },
        context: {
          ip: context[:ip],
          headers: context[:headers]
        }
      )
    end

    def notify_fraud_detection_system_of_failed_login_attempt
      castle = ::Castle::Client.new
      token = params[:castle_request_token]
      context = Castle::Context::Prepare.call(request)
      castle.filter(
        type: '$login',
        status: '$failed',
        request_token: token,
        params: {
          email: params[:session][:email]
        },
        context: {
          ip: context[:ip],
          headers: context[:headers]
        }
      )
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
      response[:risk]
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
