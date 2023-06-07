class SessionsController < ApplicationController
  include Protectable

  def new; end

  def create
    notify_fraud_detection_system_of('login.attempted')

    user = User.find_by(email: params[:session][:email].downcase)

    if user && user.authenticate(params[:session][:password]) && user.activated?
      protect_from_bad_actors(user: user, event: 'login.succeeded').on_deny do
        head :internal_server_error and return
      end

      log_in user
      params[:session][:remember_me] == '1' ? remember(user) : forget(user)
      redirect_back_or user
    elsif !user.activated?
      message  = 'Account not activated. '
      message += 'Check your email for the activation link.'
      flash[:warning] = message
      redirect_to root_url
    else
      notify_fraud_detection_system_of('login.failed')
      flash.now[:danger] = 'Invalid email/password combination'
      render 'new'
    end
  end

  def destroy
    log_out if logged_in?
    redirect_to root_url
  end
end
