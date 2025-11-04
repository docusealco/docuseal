# frozen_string_literal: true

require 'aws-sdk-cloudfront'

# Service for handling secure document access with CloudFront signed URLs
# Reuses same infrastructure and key pairs as ATS
class DocumentSecurityService
  class << self
    # Generate signed URL for a secured attachment
    # @param attachment [ActiveStorage::Attachment] The attachment to generate URL for
    # @param expires_in [ActiveSupport::Duration] How long the URL should be valid
    # @return [String] Signed CloudFront URL
    def signed_url_for(attachment, expires_in: 1.hour)
      return attachment.url unless cloudfront_configured?

      # Get the CloudFront URL for this attachment
      cloudfront_url = build_cloudfront_url(attachment)

      # Generate signed URL using same system as ATS
      signer = cloudfront_signer
      signer.signed_url(cloudfront_url, expires: expires_in.from_now.to_i)
    rescue StandardError => e
      Rails.logger.error("Failed to generate signed URL: #{e.message}")
      # Fallback to direct URL if signing fails
      attachment.url
    end

    private

    def cloudfront_configured?
      cloudfront_base_url.present? &&
        cloudfront_key_pair_id.present? &&
        cloudfront_private_key.present?
    end

    def cloudfront_signer
      @cloudfront_signer ||= Aws::CloudFront::UrlSigner.new(
        key_pair_id: cloudfront_key_pair_id,
        private_key: cloudfront_private_key
      )
    end

    def build_cloudfront_url(attachment)
      # Convert S3 URL to CloudFront URL with DocuSeal prefix
      s3_key = attachment.blob.key
      # Ensure DocuSeal prefix for document organization
      prefixed_key = s3_key.start_with?('docuseal/') ? s3_key : "docuseal/#{s3_key}"
      "#{cloudfront_base_url}/#{prefixed_key}"
    end

    def cloudfront_base_url
      @cloudfront_base_url ||= ENV.fetch('CF_URL', nil)
    end

    def cloudfront_key_pair_id
      @cloudfront_key_pair_id ||= ENV.fetch('CF_KEY_PAIR_ID', nil)
    end

    def cloudfront_private_key
      @cloudfront_private_key ||= ENV.fetch('SECURE_ATTACHMENT_PRIVATE_KEY', nil)
    end
  end
end
