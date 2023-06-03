class SessionsController < ApplicationController
  def new; end

  def create
    user = User.find_by(email: params[:session][:email].downcase)


    if user && user.authenticate(params[:session][:password])
      if user.activated? && user_is_genuine?(user: user)
        log_in user
        params[:session][:remember_me] == '1' ? remember(user) : forget(user)
        redirect_back_or user
      elsif user_is_a_hacker?(user: user)
        head :internal_server_error
      else
        message  = 'Account not activated. '
        message += 'Check your email for the activation link.'
        flash[:warning] = message
        redirect_to root_url
      end
    else
      flash.now[:danger] = 'Invalid email/password combination'
      render 'new'
    end
  end

  def destroy
    log_out if logged_in?
    redirect_to root_url
  end
  
  private

  def user_is_genuine? user:
    !user_is_a_hacker? user: user
  end

  def user_is_a_hacker? user:
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
          registered_at: user.activated_at,
          email: user.email,
          name: user.name
        }
      )

      res[:risk] >= 0.8
    end
  end
end
