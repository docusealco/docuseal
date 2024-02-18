# frozen_string_literal: true

module Api
  class ActiveStorageBlobsProxyLegacyController < ApiBaseController
    include ActiveStorage::Streaming

    skip_before_action :authenticate_user!
    skip_authorization_check

    def show
      Rollbar.info('Blob legacy') if defined?(Rollbar)

      return render json: { error: 'Not authenticated' }, status: :unauthorized unless current_user

      blob = ActiveStorage::Blob.find_signed!(params[:signed_blob_id] || params[:signed_id])

      if blob.attachments.none? { |a| a.record.account.id == current_user.account_id }
        Rollbar.error("Blob account not found: #{blob.id}") if defined?(Rollbar)

        return head :not_found
      end

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
