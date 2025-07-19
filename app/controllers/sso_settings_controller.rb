# frozen_string_literal: true

class SsoSettingsController < ApplicationController
  before_action :load_encrypted_config
  authorize_resource :encrypted_config, only: [:show, :update]

  def show; end

  def update
    saml_config = params[:saml_config] || {}
    
    # Handle IdP metadata file upload and parsing
    if params[:idp_metadata_file].present?
      begin
        parsed_config = parse_idp_metadata(params[:idp_metadata_file])
        saml_config.merge!(parsed_config)
        
        # Save the parsed configuration immediately
        @encrypted_config.value = saml_config.to_json
        
        if @encrypted_config.save
          redirect_to settings_sso_path, notice: 'IdP metadata parsed and saved successfully!'
        else
          redirect_to settings_sso_path, alert: 'Failed to save parsed configuration. Please try again.'
        end
        return
      rescue StandardError => e
        Rails.logger.error "Failed to parse IdP metadata: #{e.message}"
        redirect_to settings_sso_path, alert: "Failed to parse IdP metadata: #{e.message}"
        return
      end
    end
    
    # Validate required fields for manual configuration
    if saml_config['idp_sso_service_url'].blank? || saml_config['idp_cert_fingerprint'].blank?
      redirect_to settings_sso_path, alert: 'Please fill in all required SAML configuration fields.'
      return
    end

    # Save the SAML configuration
    @encrypted_config.value = saml_config.to_json
    
    if @encrypted_config.save
      redirect_to settings_sso_path, notice: 'SAML configuration saved successfully.'
    else
      redirect_to settings_sso_path, alert: 'Failed to save SAML configuration. Please try again.'
    end
  rescue StandardError => e
    Rails.logger.error "Failed to save SAML config: #{e.message}"
    redirect_to settings_sso_path, alert: 'An error occurred while saving the configuration.'
  end

  private

  def load_encrypted_config
    @encrypted_config =
      EncryptedConfig.find_or_initialize_by(account: current_account, key: 'saml_configs')
  end
  
  def parse_idp_metadata(metadata_file)
    require 'nokogiri'
    
    # Read and parse the XML metadata file
    xml_content = metadata_file.read
    doc = Nokogiri::XML(xml_content)
    
    # Remove default namespace to make XPath queries simpler
    doc.remove_namespaces!
    
    config = {}
    
    # Extract Entity ID
    entity_descriptor = doc.at_xpath('//EntityDescriptor')
    config['idp_entity_id'] = entity_descriptor['entityID'] if entity_descriptor
    
    # Try SAML 2.0 SSO Service URL (Azure AD puts this in IDPSSODescriptor)
    sso_service = doc.at_xpath('//IDPSSODescriptor/SingleSignOnService[@Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST"]')
    sso_service ||= doc.at_xpath('//IDPSSODescriptor/SingleSignOnService[@Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect"]')
    
    if sso_service
      config['idp_sso_service_url'] = sso_service['Location']
    else
      # Fallback: Try WS-Federation endpoints and convert to SAML
      wsfed_endpoint = doc.at_xpath('//SecurityTokenServiceEndpoint/EndpointReference/Address')
      wsfed_endpoint ||= doc.at_xpath('//PassiveRequestorEndpoint/EndpointReference/Address')
      if wsfed_endpoint
        # Convert WS-Fed endpoint to SAML endpoint (Azure AD pattern)
        wsfed_url = wsfed_endpoint.text
        config['idp_sso_service_url'] = wsfed_url.gsub('/wsfed', '/saml2')
      end
    end
    
    # Extract SLO Service URL
    slo_service = doc.at_xpath('//IDPSSODescriptor/SingleLogoutService[@Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST"]')
    slo_service ||= doc.at_xpath('//IDPSSODescriptor/SingleLogoutService[@Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect"]')
    config['idp_slo_service_url'] = slo_service['Location'] if slo_service
    
    # Extract certificate and calculate fingerprint (try multiple locations)
    cert_element = doc.at_xpath('//IDPSSODescriptor/KeyDescriptor[@use="signing"]/KeyInfo/X509Data/X509Certificate')
    cert_element ||= doc.at_xpath('//IDPSSODescriptor/KeyDescriptor/KeyInfo/X509Data/X509Certificate')
    cert_element ||= doc.at_xpath('//KeyDescriptor[@use="signing"]/KeyInfo/X509Data/X509Certificate')
    cert_element ||= doc.at_xpath('//KeyDescriptor/KeyInfo/X509Data/X509Certificate')
    cert_element ||= doc.at_xpath('//X509Certificate')
    
    if cert_element
      cert_data = cert_element.text.gsub(/\s+/, '')
      cert_der = Base64.decode64(cert_data)
      fingerprint = Digest::SHA1.hexdigest(cert_der).upcase.scan(/../).join(':')
      config['idp_cert_fingerprint'] = fingerprint
    end
    
    # Extract Name ID formats
    name_id_format = doc.at_xpath('//IDPSSODescriptor/NameIDFormat')
    config['name_identifier_format'] = name_id_format.text if name_id_format
    
    # Set default name identifier format if not found
    config['name_identifier_format'] ||= 'urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress'
    
    # Validation
    if config['idp_sso_service_url'].blank?
      raise 'No SSO service URL found in metadata. Please ensure this is a valid SAML 2.0 or Azure AD metadata file.'
    end
    
    if config['idp_cert_fingerprint'].blank?
      raise 'No certificate found in metadata. Please ensure the metadata contains a valid X.509 certificate.'
    end
    
    config
  rescue Nokogiri::XML::SyntaxError => e
    raise "Invalid XML metadata: #{e.message}"
  end
end
