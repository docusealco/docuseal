# frozen_string_literal: true

module Users
  module_function

  def from_omniauth(oauth)
    user = User.find_by(email: oauth.info.email)

    return user if user

    User.new(email: oauth.info.email,
             first_name: oauth.extra.id_info.given_name,
             last_name: oauth.extra.id_info.family_name)
  end
end
