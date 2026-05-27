# frozen_string_literal: true

# Google's OAuth2 docs. Make sure you are familiar with all the options
# before attempting to configure this gem.
# https://developers.google.com/identity/protocols/oauth2

Rails.application.config.middleware.use OmniAuth::Builder do
  # Default usage, this will give you offline access and a refresh token
  # using default scopes 'email' and 'profile'
  #
  provider :google_oauth2, ENV['GOOGLE_CLIENT_ID'], ENV['GOOGLE_CLIENT_SECRET'], scope: 'email, profile'

  # Custom redirect_uri
  #
  # provider :google_oauth2, ENV['GOOGLE_CLIENT_ID'], ENV['GOOGLE_CLIENT_SECRET'], scope: 'email, profile', redirect_uri: 'https://localhost:3000/redirect'

  # Manual setup for offline access with a refresh token.
  #
  # provider :google_oauth2, ENV['GOOGLE_CLIENT_ID'], ENV['GOOGLE_CLIENT_SECRET'], access_type: 'offline'

  # Custom scope supporting YouTube. If you are customizing scopes, remember
  # to include the default scopes 'email' and 'profile'
  #
  # provider :google_oauth2, ENV['GOOGLE_CLIENT_ID'], ENV['GOOGLE_CLIENT_SECRET'], scope: 'https://www.googleapis.com/auth/youtube.readonly, email, profile'

  # Custom scope for users only using Google for account creation/auth and do not require a refresh token.
  #
  # provider :google_oauth2, ENV['GOOGLE_CLIENT_ID'], ENV['GOOGLE_CLIENT_SECRET'], access_type: 'online', prompt: ''
end
