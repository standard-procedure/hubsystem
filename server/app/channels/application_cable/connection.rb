module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      set_current_user || reject_unauthorized_connection
    end

    private

    def set_current_user
      self.current_user = user_from_session || user_from_token
    end

    def user_from_session
      if (session = User::Session.find_by(id: cookies.signed[:session_id]))
        session.user
      end
    end

    def user_from_token
      if (token = request.params[:token])
        access_token = Doorkeeper::AccessToken.by_token(token)
        User.find(access_token.resource_owner_id) if access_token&.accessible?
      end
    end
  end
end
