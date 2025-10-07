# frozen_string_literal: true

# == Schema Information
#
# Table name: completed_documents
#
#  id               :bigint           not null, primary key
#  sha256           :string           not null
#  storage_location :string           default("secured")
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  submitter_id     :bigint           not null
#
# Indexes
#
#  index_completed_documents_on_sha256            (sha256)
#  index_completed_documents_on_storage_location  (storage_location)
#  index_completed_documents_on_submitter_id      (submitter_id)
#
class CompletedDocument < ApplicationRecord
  belongs_to :submitter, optional: true

  has_one :completed_submitter, primary_key: :submitter_id, inverse_of: :completed_documents, dependent: :destroy

  enum storage_location: {
    legacy: 'legacy',        # Fallback for development/testing
    secured: 'secured'       # Default secured storage (shared with ATS)
  }, _suffix: true

  # Check if document uses secured storage (default for new documents)
  def uses_secured_storage?
    storage_location == 'secured'
  end

  # Get appropriate Active Storage service name
  def storage_service_name
    uses_secured_storage? ? 'aws_s3_secured' : Rails.application.config.active_storage.service
  end

  # Generate signed URL for secured documents (same system as ATS)
  # @param attachment [ActiveStorage::Attachment] The attachment to generate URL for
  # @param expires_in [ActiveSupport::Duration] How long the URL should be valid
  # @return [String] Signed CloudFront URL or regular URL for legacy storage
  def signed_url_for(attachment, expires_in: 1.hour)
    return attachment.url unless uses_secured_storage?

    DocumentSecurityService.signed_url_for(attachment, expires_in: expires_in)
  end
end
