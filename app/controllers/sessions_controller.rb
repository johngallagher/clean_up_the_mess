class SessionsController < ApplicationController
  include Protectable

  def new; end

  def create
    notify_fraud_detection_system_of_login_attempted

    user = User.find_by(email: params[:session][:email].downcase)

    if user && user.authenticate(params[:session][:password]) && user.activated?
      hacker_likelihood = fetch_hacker_likelihood(user: user, type: '$login', status: '$succeeded')
      if hacker_likelihood < 0.6
        log_in user
        params[:session][:remember_me] == '1' ? remember(user) : forget(user)
        redirect_back_or user
      elsif hacker_likelihood >= 0.6 && hacker_likelihood < 0.8
        challenge_ip_address(request.remote_ip)
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
end
