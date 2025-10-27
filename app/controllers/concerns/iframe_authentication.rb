# frozen_string_literal: true

module IframeAuthentication
  extend ActiveSupport::Concern

  private

  # Custom authentication for iframe context
  # AJAX requests from Vue components don't include the auth token that's in the iframe URL,
  # so we extract it from the HTTP referer header as a fallback
  def authenticate_from_referer
    return if signed_in?

    token = params[:auth_token] || session[:auth_token] || request.headers['X-Auth-Token']

    # If no token found, extract from referer URL (iframe page has the token)
    if token.blank? && request.referer.present?
      referer_uri = URI.parse(request.referer)
      referer_params = CGI.parse(referer_uri.query || '')
      token = referer_params['auth_token']&.first
    end

    if token.present?
      sha256 = Digest::SHA256.hexdigest(token)
      user = User.joins(:access_token).active.find_by(access_token: { sha256: sha256 })

      return unless user

      sign_in(user)
      session[:auth_token] = token
      return
    end

    Rails.logger.error "#{self.class.name}: Authentication failed - no token found. " \
                       "Params: #{params.keys}, Session has token: #{session[:auth_token].present?}, " \
                       "Referer: #{request.referer}"
    render json: { error: 'Authentication required' }, status: :unauthorized
  end
end
