class SessionsController < ApplicationController
  allow_unauthenticated_access only: %i[new create]
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to new_session_path, alert: "Try again later." }

  def new
    render Views::Sessions::New
  end

  def create
    auth = request.env["omniauth.auth"]
    identity = User::Identity.find_from_omniauth(auth)

    if identity&.user
      start_new_session_for identity.user
      redirect_to after_authentication_url
    else
      redirect_to new_session_path, alert: "No user account linked to this identity."
    end
  end

  def destroy
    terminate_session
    redirect_to new_session_path, status: :see_other
  end
end
