# frozen_string_literal: true

require 'aws-sdk-secretsmanager'

# Load CloudFront private key from AWS Secrets Manager (same as ATS)
key_secret = Rails.configuration.x.compliance_storage&.dig(:cf_key_secret)

if key_secret.present?
  begin
    client = Aws::SecretsManager::Client.new
    response = client.get_secret_value(secret_id: key_secret)
    ENV['SECURE_ATTACHMENT_PRIVATE_KEY'] = response.secret_string
    Rails.logger.info('Successfully loaded CloudFront private key from Secrets Manager')
  rescue StandardError => e
    Rails.logger.error("Failed to load CloudFront private key: #{e.message}")
  end
end
