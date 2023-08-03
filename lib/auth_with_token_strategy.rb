# frozen_string_literal: true

class AuthWithTokenStrategy < Devise::Strategies::Base
  def valid?
    request.headers['X-Auth-Token'].present?
  end

  def authenticate!
    payload = JsonWebToken.decode(request.headers['X-Auth-Token'])

    user = User.find_by(uuid: payload['uuid'])

    if user
      success!(user)
    else
      fail!('Invalid token')
    end
  rescue JWT::VerificationError
    fail!('Invalid token')
  end
end
