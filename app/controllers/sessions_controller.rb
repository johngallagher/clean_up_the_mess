class SessionsController < ApplicationController
  def new; end

  def create
    notify_fraud_detection_system_of_login_attempted

    user = User.find_by(email: params[:session][:email].downcase)

    if user && user.authenticate(params[:session][:password]) && user.activated?
      if user_is_genuine?(user: user)
        log_in user
        params[:session][:remember_me] == '1' ? remember(user) : forget(user)
        redirect_back_or user
      else
        block_ip_address(request.remote_ip)
        head :internal_server_error
      end
    elsif !user.activated?
      message  = 'Account not activated. '
      message += 'Check your email for the activation link.'
      flash[:warning] = message
      redirect_to root_url
    else
      notify_fraud_detection_system_of_failed_login_attempt
      flash.now[:danger] = 'Invalid email/password combination'
      render 'new'
    end
  end

  def destroy
    log_out if logged_in?
    redirect_to root_url
  end

  private

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

  def user_is_genuine?(user:)
    !user_is_a_hacker? user: user
  end

  def user_is_a_hacker?(user:)
    castle = ::Castle::Client.new

    begin
      token = request.params[:castle_request_token]
      context = Castle::Context::Prepare.call(request)

      res = castle.risk(
        type: '$login',
        status: '$succeeded',
        request_token: token,
        context: {
          ip: context[:ip],
          headers: context[:headers]
        },
        user: {
          id: user.id.to_s,
          registered_at: user.activated_at.iso8601,
          email: user.email,
          name: user.name
        }
      )

      res[:risk] >= 0.8
    end
  end

  def block_ip_address(ip)
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
    request.body = JSON.generate({ configuration: { target: 'ip', value: ip }, mode: 'block' })

    http.request(request)
  end
end
