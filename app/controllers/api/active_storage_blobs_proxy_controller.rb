# frozen_string_literal: true

module Api
  class ActiveStorageBlobsProxyController < ApiBaseController
    include ActiveStorage::Streaming

    skip_before_action :authenticate_user!
    skip_authorization_check

    before_action :set_cors_headers
    before_action :set_noindex_headers

    def show
      blob_uuid, purp, exp = ApplicationRecord.signed_id_verifier.verified(params[:signed_uuid])

      if blob_uuid.blank? || purp != 'blob'
        Rollbar.error('Blob not found') if defined?(Rollbar)

        return head :not_found
      end

      blob = ActiveStorage::Blob.find_by!(uuid: blob_uuid)

      attachment = blob.attachments.take

      @record = attachment.record
      @record = @record.record if @record.is_a?(ActiveStorage::Attachment)

      authorization_check!(attachment, @record, exp)

      if request.headers['Range'].present?
        send_blob_byte_range_data blob, request.headers['Range']
      else
        http_cache_forever public: true do
          response.headers['Accept-Ranges'] = 'bytes'
          response.headers['Content-Length'] = blob.byte_size.to_s

          send_blob_stream blob, disposition: params[:disposition]
        end
      end
    end

    private

    def authorization_check!(attachment, record, exp)
      return if attachment.name == 'logo'
      return if exp.to_i >= Time.current.to_i
      return if current_user && current_ability.can?(:read, record)

      if exp.blank?
        configs = record.account.account_configs.where(key: [AccountConfig::DOWNLOAD_LINKS_AUTH_KEY,
                                                             AccountConfig::DOWNLOAD_LINKS_EXPIRE_KEY])

        require_auth = configs.any? { |c| c.key == AccountConfig::DOWNLOAD_LINKS_AUTH_KEY && c.value }
        require_ttl = configs.none? { |c| c.key == AccountConfig::DOWNLOAD_LINKS_EXPIRE_KEY && c.value == false }

        return if !require_ttl && !require_auth
      end

      Rollbar.error('Blob unauthorized') if defined?(Rollbar)

      raise CanCan::AccessDenied
    end
  end
end
