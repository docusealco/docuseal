# frozen_string_literal: true

module Submitters
  module FindRememberedSignature
    SIGNED_UUID_PURPOSE = 'signature'

    module_function

    def call(submitter, params, cookies = nil)
      if params[:signed_signature_uuids].present?
        find_storage_signature(submitter, params[:signed_signature_uuids])
      elsif cookies
        find_session_signature(submitter, cookies)
      end
    end

    def sign_signature_uuid(uuid)
      ApplicationRecord.signed_id_verifier.generate(uuid, purpose: SIGNED_UUID_PURPOSE)
    end

    def verify_signature_uuid(signed_uuid)
      ApplicationRecord.signed_id_verifier.verified(signed_uuid, purpose: SIGNED_UUID_PURPOSE)
    end

    def find_storage_signature(submitter, signed_uuids)
      signed_uuid = signed_uuids[submitter.email]

      return if signed_uuid.blank?

      uuid = verify_signature_uuid(signed_uuid)

      return if uuid.blank?

      find_signature_from_uuid(submitter, uuid)
    end

    def find_session_signature(submitter, cookies)
      values =
        begin
          JSON.parse(cookies.encrypted[:signature_uuids].presence || '{}')
        rescue JSON::ParserError
          {}
        end

      return if values.blank?

      uuid = values[submitter.email]

      return if uuid.blank?

      find_signature_from_uuid(submitter, uuid)
    end

    def find_signature_from_uuid(submitter, uuid)
      signature_attachment = ActiveStorage::Attachment.find_by(uuid:)

      return unless signature_attachment

      return if signature_attachment.record.email != submitter.email

      signature_attachment
    end
  end
end
