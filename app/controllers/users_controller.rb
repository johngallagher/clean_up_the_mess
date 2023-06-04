class UsersController < ApplicationController
  before_action :logged_in_user, only: %i[index edit update destroy
                                          following followers]
  before_action :correct_user,   only: %i[edit update]
  before_action :admin_user,     only: :destroy

  def index
    @users = User.paginate(page: params[:page])
  end

  def show
    @user = User.find(params[:id])
    @microposts = @user.microposts.paginate(page: params[:page])
  end

  def new
    @user = User.new
  end

  def create
    notify_fraud_detection_system_of_registration_attempted
    @user = User.new(user_params)
    if @user.save
      if user_is_genuine?(user: @user)
        @user.send_activation_email
        flash[:info] = 'Please check your email to activate your account.'
        redirect_to root_url
      else
        challenge_ip_address(request.remote_ip)
        render 'new'
      end
    else
      notify_fraud_detection_system_of_registration_failed
      render 'new'
    end
  end

  def edit
    @user = User.find(params[:id])
  end

  def update
    @user = User.find(params[:id])
    if @user.update(user_params)
      flash[:success] = 'Profile updated'
      redirect_to @user
    else
      render 'edit'
    end
  end

  def destroy
    User.find(params[:id]).destroy
    flash[:success] = 'User deleted'
    redirect_to users_url
  end

  def following
    @title = 'Following'
    @user  = User.find(params[:id])
    @users = @user.following.paginate(page: params[:page])
    render 'show_follow'
  end

  def followers
    @title = 'Followers'
    @user  = User.find(params[:id])
    @users = @user.followers.paginate(page: params[:page])
    render 'show_follow'
  end

  private

  def user_params
    params.require(:user).permit(:name, :email, :password,
                                 :password_confirmation)
  end

  # Before filters

  # Confirms the correct user.
  def correct_user
    @user = User.find(params[:id])
    redirect_to(root_url) unless current_user?(@user)
  end

  # Confirms an admin user.
  def admin_user
    redirect_to(root_url) unless current_user.admin?
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

  def user_is_genuine?(user:)
    castle = ::Castle::Client.new
    token = params[:castle_request_token]
    context = Castle::Context::Prepare.call(request)
    response = castle.risk(
      type: '$registration',
      status: '$succeeded',
      request_token: token,
      user: {
        id: user.id.to_s,
        email: user.email
      },
      context: {
        ip: context[:ip],
        headers: context[:headers]
      }
    )
    response[:risk] < 0.8
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

  def challenge_ip_address(ip)
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
    request.body = JSON.generate({ configuration: { target: 'ip', value: ip }, mode: 'challenge' })

    http.request(request)
  end
end
