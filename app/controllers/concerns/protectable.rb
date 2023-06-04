module Protectable
  extend ActiveSupport::Concern

  included do
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

    def user_is_a_hacker?(user:, type:, status: '', name: '')
      !user_is_genuine?(user: user, type: type, status: status, name: name)
    end

    def user_is_genuine?(user:, type:, status: '', name: '')
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
      response[:risk] < 0.8
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
  end
end
