# frozen_string_literal: true

class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  # See https://github.com/omniauth/omniauth/wiki/FAQ#rails-session-is-clobbered-after-callback-on-developer-strategy
  skip_before_action :verify_authenticity_token, only: [:saml, :google_oauth2, :microsoft_graph]

  def saml
    handle_omniauth_callback('SAML')
  end

  def google_oauth2
    handle_omniauth_callback('Google')
  end

  def microsoft_graph
    handle_omniauth_callback('Microsoft')
  end

  def failure
    Rails.logger.error "Omniauth failure: #{params[:message]}"
    redirect_to new_user_session_path, alert: "Authentication failed: #{params[:message]}"
  end

  def passthru
    # Handle requests to unconfigured or improperly configured SSO providers
    provider = params[:provider] || request.env['omniauth.strategy']&.name&.to_s
    
    case provider
    when 'saml'
      # Check if SAML is properly configured anywhere in the system
      saml_configured = false
      
      # Check environment variables first
      if ENV['SAML_IDP_SSO_SERVICE_URL'].present? && ENV['SAML_IDP_CERT_FINGERPRINT'].present?
        saml_configured = true
      else
        # Check if any account has SAML configured in database
        saml_config_record = EncryptedConfig.find_by(key: 'saml_configs')
        if saml_config_record&.value.present?
          begin
            config = JSON.parse(saml_config_record.value)
            saml_configured = config['idp_sso_service_url'].present? && config['idp_cert_fingerprint'].present?
          rescue JSON::ParserError
            # Invalid JSON, treat as not configured
          end
        end
      end
      
      unless saml_configured
        redirect_to new_user_session_path, alert: 'SAML SSO is not configured. Please contact your administrator to set up SAML authentication.'
        return
      end
    when 'google_oauth2'
      if Rails.application.credentials.google_client_id.blank? || Rails.application.credentials.google_client_id == 'placeholder_client_id'
        redirect_to new_user_session_path, alert: 'Google OAuth is not configured. Please contact your administrator to set up Google authentication.'
        return
      end
    when 'microsoft_graph'
      if Rails.application.credentials.microsoft_client_id.blank? || Rails.application.credentials.microsoft_client_id == 'placeholder_client_id'
        redirect_to new_user_session_path, alert: 'Microsoft OAuth is not configured. Please contact your administrator to set up Microsoft authentication.'
        return
      end
    end
    
    # If we get here, redirect to configuration page
    provider_name = provider&.humanize || 'SSO'
    redirect_to new_user_session_path, alert: "#{provider_name} authentication is not available. Please contact your administrator."
  end

  def metadata
    # Generate basic SAML metadata for the service provider
    entity_id = ENV.fetch('SAML_SP_ENTITY_ID', 'docuseal')
    app_url = ENV.fetch('APP_URL', 'http://localhost:3000')
    callback_url = "#{app_url}/auth/saml/callback"
    
    # Build comprehensive SP metadata XML
    logout_url = "#{app_url}/sign_out"
    
    metadata_xml = <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <md:EntityDescriptor xmlns:md="urn:oasis:names:tc:SAML:2.0:metadata"
                           entityID="#{entity_id}">
        <md:SPSSODescriptor 
          AuthnRequestsSigned="false" 
          WantAssertionsSigned="true" 
          protocolSupportEnumeration="urn:oasis:names:tc:SAML:2.0:protocol">
          
          <!-- Name ID Format -->
          <md:NameIDFormat>urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress</md:NameIDFormat>
          
          <!-- Assertion Consumer Services -->
          <md:AssertionConsumerService
            Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST"
            Location="#{callback_url}"
            index="0"
            isDefault="true" />
          <md:AssertionConsumerService
            Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect"
            Location="#{callback_url}"
            index="1" />
            
          <!-- Single Logout Service -->
          <md:SingleLogoutService
            Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST"
            Location="#{logout_url}" />
          <md:SingleLogoutService
            Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect"
            Location="#{logout_url}" />
            
        </md:SPSSODescriptor>
      </md:EntityDescriptor>
    XML
    
    response.headers['Content-Disposition'] = 'attachment; filename="saml-metadata.xml"'
    render xml: metadata_xml, content_type: 'application/samlmetadata+xml'
  end

  private

  def handle_omniauth_callback(provider_name)
    @user = User.from_omniauth(request.env['omniauth.auth'])

    if @user&.persisted?
      sign_in_and_redirect @user, event: :authentication
      set_flash_message(:notice, :success, kind: provider_name) if is_navigational_format?
    else
      # Store the omniauth data in session for potential account linking
      session['devise.omniauth_data'] = request.env['omniauth.auth'].except(:extra)
      
      # Redirect to registration with error message
      redirect_to new_user_registration_url, 
                  alert: "There was an issue with your #{provider_name} account. Please try again or contact support."
    end
  rescue StandardError => e
    Rails.logger.error "Omniauth callback error: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    
    redirect_to new_user_session_path, 
                alert: "Authentication failed. Please try again or contact support."
  end
end
