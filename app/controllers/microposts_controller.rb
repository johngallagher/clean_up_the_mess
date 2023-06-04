class MicropostsController < ApplicationController
  before_action :logged_in_user, only: %i[create destroy]
  before_action :correct_user,   only: :destroy

  def create
    if user_is_a_hacker?(user: current_user)
      challenge_ip_address(request.remote_ip)
      head :internal_server_error and return
    end

    @micropost = current_user.microposts.build(micropost_params)
    @micropost.image.attach(params[:micropost][:image])
    if @micropost.save
      flash[:success] = 'Micropost created!'
      redirect_to root_url
    else
      @feed_items = current_user.feed.paginate(page: params[:page])
      render 'static_pages/home'
    end
  end

  def destroy
    @micropost.destroy
    flash[:success] = 'Micropost deleted'
    redirect_to request.referrer || root_url
  end

  private

  def micropost_params
    params.require(:micropost).permit(:content, :image)
  end

  def correct_user
    @micropost = current_user.microposts.find_by(id: params[:id])
    redirect_to root_url if @micropost.nil?
  end

  def user_is_a_hacker?(user:)
    castle = ::Castle::Client.new

    token = request.params[:castle_request_token]
    context = Castle::Context::Prepare.call(request)

    res = castle.risk(
      type: '$custom',
      name: 'Created a micropost',
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
