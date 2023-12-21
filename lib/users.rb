# frozen_string_literal: true

module Users
  module_function

  def from_omniauth(oauth)
    user = User.find_by(email: oauth.info.email.to_s.downcase)

    return user if user

    case oauth['provider'].to_s
    when 'google_oauth2'
      User.new(email: oauth.info.email,
               first_name: oauth.extra.id_info.given_name,
               last_name: oauth.extra.id_info.family_name)
    when 'microsoft_office365'
      User.new(email: oauth.info.email,
               first_name: oauth.info.first_name,
               last_name: oauth.info.last_name)
    when 'github'
      User.new(email: oauth.info.email, first_name: oauth.info.name)
    end
  end
end
