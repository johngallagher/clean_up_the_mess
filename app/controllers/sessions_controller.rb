class SessionsController < ApplicationController
  def new; end

  def allow_login?
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
          id: 'ca1242f498', # Required. A unique, persistent user identifier
          registered_at: '2012-12-02T00:30:08.276Z', # Recommended
          email: 'mgray@example.com', # Recommended
          phone: '+1415232183', # Optional. E.164 format
          name: 'Mike Gray', # Optional
          address: { # Optional
            line1: '200 Fell St',
            line2: 'Apt 1028',
            city: 'San Francisco',
            postal_code: '94103',
            region_code: 'CA',
            country_code: 'US' # Required. ISO-3166 country code
          },
          traits: { # Custom user data for visualization purposes
            nationality: 'US',
            birth_date: '1976-02-02'
          }
        },
        authentication_method: { # Optional. See link below
          type: '$password' # The most common type
        },
        properties: { # Custom event data for visualization purposes
          solved_captcha: true,
          attempts: 3
        }
      )

      res[:risk] < 0.8
    rescue Castle::InvalidRequestTokenError
      false
    rescue Castle::Error => e
      true
    end
  end

  def create
    user = User.find_by(email: params[:session][:email].downcase)

    unless allow_login?
      head :internal_server_error and return
    end

    if user && user.authenticate(params[:session][:password])
      if user.activated?
        log_in user
        params[:session][:remember_me] == '1' ? remember(user) : forget(user)
        redirect_back_or user
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
end
