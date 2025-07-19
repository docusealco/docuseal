# frozen_string_literal: true

class SamlConfigService
  def self.load_config(account = nil)
    # Try to load from database first
    if account
      config_record = EncryptedConfig.find_by(account: account, key: 'saml_configs')
      if config_record&.value.present?
        return JSON.parse(config_record.value).with_indifferent_access
      end
    end
    
    # Fall back to environment variables
    {
      idp_sso_service_url: ENV['SAML_IDP_SSO_SERVICE_URL'],
      idp_cert_fingerprint: ENV['SAML_IDP_CERT_FINGERPRINT'],
      sp_entity_id: ENV.fetch('SAML_SP_ENTITY_ID', 'docuseal'),
      name_identifier_format: 'urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress',
      email_attribute: 'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress',
      first_name_attribute: 'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/givenname',
      last_name_attribute: 'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/surname',
      name_attribute: 'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name'
    }.with_indifferent_access
  rescue => e
    Rails.logger.warn "Could not load SAML config: #{e.message}"
    {}
  end
  
  def self.configured?(account = nil)
    config = load_config(account)
    config[:idp_sso_service_url].present? && config[:idp_cert_fingerprint].present?
  end
  
  def self.omniauth_config(account = nil)
    config = load_config(account)
    return nil unless configured?(account)
    
    {
      assertion_consumer_service_url: "#{ENV.fetch('APP_URL', 'http://localhost:3000')}/auth/saml/callback",
      sp_entity_id: config[:sp_entity_id],
      idp_sso_service_url: config[:idp_sso_service_url],
      idp_cert_fingerprint: config[:idp_cert_fingerprint],
      name_identifier_format: config[:name_identifier_format],
      attribute_statements: {
        email: [config[:email_attribute]],
        first_name: [config[:first_name_attribute]],
        last_name: [config[:last_name_attribute]],
        name: [config[:name_attribute]]
      }
    }
  end
end
