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

      if blob_uuid.blank? || (purp.present? && purp != 'blob') || (exp && exp < Time.current.to_i)
        Rollbar.error('Blob not found') if defined?(Rollbar)

        return head :not_found
      end

      blob = ActiveStorage::Blob.find_by!(uuid: blob_uuid)

      authorization_check!(blob) if exp.blank?

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

    def authorization_check!(blob)
      is_authorized =
        blob.attachments.all? do |a|
          a.name.in?(%w[logo preview_images]) ||
            (current_user && a.record.account.id == current_user.account_id) ||
            !a.record.account.account_configs.find_or_initialize_by(key: AccountConfig::DOWNLOAD_LINKS_AUTH_KEY).value
        end

      return if is_authorized

      Rollbar.error('Blob aunauthorized') if defined?(Rollbar)

      raise CanCan::AccessDenied
    end
  end
end
