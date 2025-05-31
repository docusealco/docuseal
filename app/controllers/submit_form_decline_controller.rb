# frozen_string_literal: true

class SubmitFormDeclineController < ApplicationController
  skip_before_action :authenticate_user!
  skip_authorization_check

  def create
    submitter = Submitter.find_by!(slug: params[:submit_form_slug])

    return redirect_to submit_form_path(submitter.slug) if submitter.declined_at? ||
                                                           submitter.completed_at? ||
                                                           submitter.submission.archived_at? ||
                                                           submitter.submission.expired? ||
                                                           submitter.submission.template&.archived_at?

    ApplicationRecord.transaction do
      submitter.update!(declined_at: Time.current)

      SubmissionEvents.create_with_tracking_data(submitter, 'decline_form', request, { reason: params[:reason] })
    end

    user = submitter.submission.created_by_user || submitter.template.author

    if user.user_configs.find_by(key: UserConfig::RECEIVE_DECLINED_EMAIL)&.value != false
      SubmitterMailer.declined_email(submitter, user).deliver_later!
    end

    WebhookUrls.for_account_id(submitter.account_id, 'form.declined').each do |webhook_url|
      SendFormDeclinedWebhookRequestJob.perform_async('submitter_id' => submitter.id,
                                                      'webhook_url_id' => webhook_url.id)
    end

    redirect_to submit_form_path(submitter.slug)
  end
end
