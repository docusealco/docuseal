# frozen_string_literal: true

module Submitters
  module MaybeAssignDefaultBrowserSignature
    SIGNED_UUID_PURPPOSE = 'signature'

    module_function

    def call(submitter, params, cookies = nil, attachments = [])
      if (value = params[:signature_src].presence || params[:signature].presence)
        find_or_create_signature_from_value(submitter, value, attachments)
      elsif params[:signed_signature_uuids].present?
        find_storage_signature(submitter, params[:signed_signature_uuids], attachments)
      elsif cookies
        find_session_signature(submitter, cookies, attachments)
      end
    end

    def find_or_create_signature_from_value(submitter, value, attachments)
      _, attachment = Submitters::NormalizeValues.normalize_attachment_value(value,
                                                                             'signature',
                                                                             submitter.account,
                                                                             attachments,
                                                                             submitter)

      attachment.record ||= submitter

      attachment.save!

      attachment
    end

    def sign_signature_uuid(uuid)
      ApplicationRecord.signed_id_verifier.generate(uuid, purpose: SIGNED_UUID_PURPPOSE)
    end

    def verify_signature_uuid(signed_uuid)
      ApplicationRecord.signed_id_verifier.verified(signed_uuid, purpose: SIGNED_UUID_PURPPOSE)
    end

    def find_storage_signature(submitter, signed_uuids, attachments)
      signed_uuid = signed_uuids[submitter.email]

      return if signed_uuid.blank?

      uuid = verify_signature_uuid(signed_uuid)

      return if uuid.blank?

      find_signature_from_uuid(submitter, uuid, attachments)
    end

    def find_session_signature(submitter, cookies, attachments)
      values =
        begin
          JSON.parse(cookies.encrypted[:signature_uuids].presence || '{}')
        rescue JSON::ParserError
          {}
        end

      return if values.blank?

      uuid = values[submitter.email]

      return if uuid.blank?

      find_signature_from_uuid(submitter, uuid, attachments)
    end

    def find_signature_from_uuid(submitter, uuid, attachments)
      signature_attachment = ActiveStorage::Attachment.find_by(uuid:)

      return unless signature_attachment

      return if signature_attachment.record.email != submitter.email

      existing_attachment = attachments.find do |a|
        a.blob_id == signature_attachment.blob_id && submitter.id == a.record_id
      end

      return existing_attachment if existing_attachment

      submitter.attachments_attachments.create_or_find_by!(blob_id: signature_attachment.blob_id)
    end
  end
end
