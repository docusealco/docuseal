# frozen_string_literal: true

class AuthWithTokenStrategy < Devise::Strategies::Base
  def valid?
    request.headers['X-Auth-Token'].present?
  end

  def authenticate!
    sha256 = Digest::SHA256.hexdigest(request.headers['X-Auth-Token'])

    user = User.joins(:access_token).find_by(access_token: { sha256: })

    if user
      success!(user)
    else
      fail!('Invalid token')
    end
  rescue JWT::VerificationError
    fail!('Invalid token')
  end
end
