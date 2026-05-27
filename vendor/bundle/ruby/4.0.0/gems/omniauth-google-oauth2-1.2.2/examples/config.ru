# frozen_string_literal: true

# Sample app for Google OAuth2 Strategy
# Make sure to setup the ENV variables GOOGLE_KEY and GOOGLE_SECRET
# Run with "bundle exec rackup"

require 'rubygems'
require 'bundler'
require 'sinatra'
require 'omniauth'
require 'omniauth-google-oauth2'

# Do not use for production code.
# This is only to make setup easier when running through the sample.
#
# If you do have issues with certs in production code, this could help:
# http://railsapps.github.io/openssl-certificate-verify-failed.html
OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE

# Main example app for omniauth-google-oauth2
class App < Sinatra::Base
  configure do
    set :sessions, true
    set :inline_templates, true
  end

  use Rack::Session::Cookie, secret: ENV['RACK_COOKIE_SECRET']

  use OmniAuth::Builder do
    # For additional provider examples please look at 'omni_auth.rb'
    # The key provider_ignores_state is only for AJAX flows. It is not recommended for normal logins.
    provider :google_oauth2, ENV['GOOGLE_KEY'], ENV['GOOGLE_SECRET'], access_type: 'offline', prompt: 'consent', provider_ignores_state: true, scope: 'email,profile'
  end

  get '/' do
    <<-HTML
    <!DOCTYPE html>
    <html>
      <head>
        <title>Google OAuth2 Example</title>
      </head>

      <body>
        <ul>
          <li>
            <form method="post" action="/auth/google_oauth2">
              <input type="hidden" name="authenticity_token" value="#{request.env['rack.session']['csrf']}">
              <button type="submit">Login with Google</button>
            </form>
          </li>

          <li>
            <a href="#" class="googleplus-login">Sign in with Google via AJAX</a>
          </li>
        </ul>

        <script>
          const a = document.querySelector('.googleplus-login');

          const handleGoogleOauthSignIn = () => {
            const oauth2Endpoint = 'https://accounts.google.com/o/oauth2/v2/auth';

            const params = new URLSearchParams({
              client_id: '#{ENV['GOOGLE_KEY']}',
              prompt: 'select_account',
              redirect_uri: 'http://localhost:3000/callback',
              response_type: 'code',
              scope: 'email openid profile',
            });

            const url = `${oauth2Endpoint}?${params.toString()}`;
            window.location.href = url;
          }

          a.addEventListener('click', event => {
            event.preventDefault();
            handleGoogleOauthSignIn();
          });
        </script>
      </body>
    </html>
    HTML
  end

  get '/callback' do
    <<-HTML
    <!DOCTYPE html>
    <html>
      <head>
        <title>Google OAuth2 Example</title>
      </head>

      <body>
        <p>Redirected</p>

        <script>
          const handleGoogleOauthCallback = async () => {
            const params = new URL(document.location.toString()).searchParams;
            const code = params.get('code');

            const response = fetch('http://localhost:3000/auth/google_oauth2/callback', {
              body: JSON.stringify({ code, redirect_uri: 'http://localhost:3000/callback' }),
              headers: {
                'Content-type': 'application/json',
              },
              method: 'POST',
            });
          }

          handleGoogleOauthCallback();
        </script>
      </body>
    </html>
    HTML
  end

  post '/auth/:provider/callback' do
    content_type 'text/plain'
    begin
      request.env['omniauth.auth'].to_hash.inspect
    rescue StandardError
      'No Data'
    end
  end

  get '/auth/:provider/callback' do
    content_type 'text/plain'
    begin
      request.env['omniauth.auth'].to_hash.inspect
    rescue StandardError
      'No Data'
    end
  end

  get '/auth/failure' do
    content_type 'text/plain'
    begin
      request.env['omniauth.auth'].to_hash.inspect
    rescue StandardError
      'No Data'
    end
  end
end

run App.new
