# frozen_string_literal: true

module Api
  class ActiveStorageBlobsProxyController < ApiBaseController
    include ActiveStorage::Streaming

    skip_before_action :authenticate_user!
    skip_authorization_check

    before_action :set_cors_headers

    def show
      blob_uuid, = ApplicationRecord.signed_id_verifier.verified(params[:signed_uuid])

      if blob_uuid.blank?
        Rollbar.error('Blob not found') if defined?(Rollbar)

        return head :not_found
      end

      blob = ActiveStorage::Blob.find_by!(uuid: blob_uuid)

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
  end
end
