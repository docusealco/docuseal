# frozen_string_literal: true

class SubmitFormDownloadController < ApplicationController
  skip_before_action :authenticate_user!
  skip_authorization_check

  FILES_TTL = 5.minutes

  def index
    @submitter = Submitter.find_by!(slug: params[:submit_form_slug])

    return redirect_to submitter_download_index_path(@submitter.slug) if @submitter.completed_at?

    return head :unprocessable_entity if @submitter.declined_at? ||
                                         @submitter.submission.archived_at? ||
                                         @submitter.submission.expired? ||
                                         @submitter.submission.template&.archived_at? ||
                                         AccountConfig.exists?(account_id: @submitter.account_id,
                                                               key: AccountConfig::ALLOW_TO_PARTIAL_DOWNLOAD_KEY,
                                                               value: false)

    last_completed_submitter = @submitter.submission.submitters
                                         .where.not(id: @submitter.id)
                                         .where.not(completed_at: nil)
                                         .max_by(&:completed_at)

    attachments =
      if last_completed_submitter
        Submitters.select_attachments_for_download(last_completed_submitter)
      else
        @submitter.submission.schema_documents.preload(:blob)
      end

    urls = attachments.map do |attachment|
      ActiveStorage::Blob.proxy_url(attachment.blob, expires_at: FILES_TTL.from_now.to_i)
    end

    render json: urls
  end
end
