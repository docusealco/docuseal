# frozen_string_literal: true

class TokenRefreshService
  def initialize(params)
    @params = params
  end

  def refresh_token
    user = find_user
    return nil unless user

    user.access_token&.destroy
    user.association(:access_token).reset
    user.reload

    user.create_access_token!
    user.access_token.token
  end

  private

  def find_user
    external_user_id = @params.dig(:user, :external_id)&.to_i
    return nil unless external_user_id

    user = User.find_by(external_user_id: external_user_id)

    Rails.logger.warn "Token refresh requested for non-existent user: external_id #{external_user_id}" unless user

    user
  end
end
