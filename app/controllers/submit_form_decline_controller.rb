# frozen_string_literal: true

class SubmitFormDeclineController < ApplicationController
  skip_before_action :authenticate_user!
  skip_authorization_check

  before_action :load_submitter

  def create
    return redirect_to submit_form_path(@submitter.slug) if @submitter.declined_at? ||
                                                            @submitter.completed_at? ||
                                                            @submitter.submission.voided_at? ||
                                                            @submitter.submission.archived_at? ||
                                                            @submitter.submission.expired? ||
                                                            @submitter.submission.template&.archived_at? ||
                                                            !Submitters::AuthorizedForForm.call(@submitter,
                                                                                                current_user,
                                                                                                request)

    ApplicationRecord.transaction do
      @submitter.update!(declined_at: Time.current)

      SubmissionEvents.create_with_tracking_data(@submitter, 'decline_form', request, { reason: params[:reason] })
    end

    user = @submitter.submission.created_by_user || @submitter.template.author

    if user.user_configs.find_by(key: UserConfig::RECEIVE_DECLINED_EMAIL)&.value != false
      SubmitterMailer.declined_email(@submitter, user).deliver_later!
    end

    WebhookUrls.enqueue_events(@submitter, 'form.declined')

    redirect_to submit_form_path(@submitter.slug)
  end

  private

  def load_submitter
    @submitter = Submitter.find_by!(slug: params[:submit_form_slug])
  end
end
