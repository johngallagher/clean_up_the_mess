class SessionsController < ApplicationController
  include Protectable

  def new; end

  def create
    notify_fraud_detection_system_of_login_attempted

    user = User.find_by(email: params[:session][:email].downcase)

    if user && user.authenticate(params[:session][:password]) && user.activated?
      risk_score = assess_risk_of_a_bad_actor_logging_in(user: user)

      # [^8]
      if risk_score.high?
        block_ip_address(request.remote_ip)
        head :internal_server_error and return
      end

      # [^8]
      if risk_score.medium?
        challenge_ip_address(request.remote_ip) 
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
