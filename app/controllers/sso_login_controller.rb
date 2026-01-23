# frozen_string_literal: true

class SsoLoginController < ApplicationController
  skip_before_action :maybe_redirect_to_setup
  skip_before_action :authenticate_user!
  skip_authorization_check

  # SSO JWT secret key for decoding tokens
  SSO_JWT_SECRET = '6a5a4fa4733123c991256f5b0f2221fbe8f7b4c210f74fba621b44c9d5e9f8b6'.freeze

  def login
    token = params[:token]

    unless token.present?
      return redirect_to root_path, alert: 'Missing authentication token'
    end

    begin
      # Decode JWT token using the SSO secret key
      decoded_token = decode_sso_jwt(token)
      
      email = decoded_token['email']&.downcase
      first_name = decoded_token['first_name']
      last_name = decoded_token['last_name']

      unless email.present?
        return redirect_to root_path, alert: 'Invalid token: email missing'
      end

      # Find or create user
      user = find_or_create_user(email, first_name, last_name)

      if user
        # Sign in the user
        sign_in(user)
        
        # Redirect to dashboard
        redirect_to root_path, notice: 'Signed in successfully'
      else
        redirect_to root_path, alert: 'Unable to sign in'
      end
    rescue JWT::DecodeError, JWT::ExpiredSignature => e
      Rails.logger.error("SSO JWT decode error: #{e.message}")
      redirect_to root_path, alert: 'Invalid or expired authentication token'
    rescue StandardError => e
      Rails.logger.error("SSO login error: #{e.message}")
      Rails.logger.error(e.backtrace.join("\n"))
      redirect_to root_path, alert: 'An error occurred during sign in'
    end
  end

  private

  def decode_sso_jwt(token)
    # Decode JWT with the SSO secret key
    decoded = JWT.decode(token, SSO_JWT_SECRET, true, { algorithm: 'HS256' })
    decoded[0] # Return the payload
  end

  def find_or_create_user(email, first_name, last_name)
    # Try to find existing user by email
    user = User.find_by(email: email)

    if user
      # Update user info if provided and different
      update_attrs = {}
      update_attrs[:first_name] = first_name if first_name.present? && user.first_name != first_name
      update_attrs[:last_name] = last_name if last_name.present? && user.last_name != last_name
      
      user.update(update_attrs) if update_attrs.any?

      return user
    end

    # User doesn't exist, create a new one
    # Find or create an account
    account = find_or_create_account

    # Generate a random password for the new user
    password = SecureRandom.hex(16)

    # Create the new user
    user = account.users.build(
      email: email,
      first_name: first_name || '',
      last_name: last_name || '',
      password: password,
      role: User::ADMIN_ROLE
    )

    if user.save
      user
    else
      Rails.logger.error("Failed to create user: #{user.errors.full_messages.join(', ')}")
      nil
    end
  end

  def find_or_create_account
    # Try to find the first active account
    account = Account.active.first

    # If no account exists, create a default one
    unless account
      account = Account.create!(
        name: 'Default Account',
        timezone: 'UTC',
        locale: 'en-US'
      )

      # Create encrypted configs if needed
      if EncryptedConfig.table_exists?
        app_url = Docuseal.default_url_options[:host] || request.host
        app_url = "https://#{app_url}" unless app_url.start_with?('http')

        encrypted_configs = [
          { key: EncryptedConfig::APP_URL_KEY, value: app_url }
        ]

        # Only add ESIGN certs if GenerateCertificate is available
        begin
          encrypted_configs << {
            key: EncryptedConfig::ESIGN_CERTS_KEY,
            value: GenerateCertificate.call.transform_values(&:to_pem)
          }
        rescue NameError, StandardError => e
          Rails.logger.warn("Could not generate ESIGN certificates: #{e.message}")
        end

        account.encrypted_configs.create!(encrypted_configs) if encrypted_configs.any?
      end

      # Create account configs if needed
      if AccountConfig.table_exists? && SearchEntry.table_exists?
        account.account_configs.create!(key: :fulltext_search, value: true)
      end
    end

    account
  end
end
