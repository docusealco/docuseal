# frozen_string_literal: true

class SubmittersSendEmailController < ApplicationController
  load_and_authorize_resource :submitter, id_param: :submitter_slug, find_by: :slug

  def create
    if Docuseal.multitenant? && SubmissionEvent.exists?(submitter: @submitter,
                                                        event_type: 'send_email',
                                                        created_at: 10.hours.ago..Time.current)
      Rollbar.warning("Already sent: #{@submitter.id}") if defined?(Rollbar)

      return redirect_back(fallback_location: submission_path(@submitter.submission),
                           alert: I18n.t('email_has_been_sent_already'))
    end

    SendSubmitterInvitationEmailJob.perform_async('submitter_id' => @submitter.id)

    @submitter.sent_at ||= Time.current
    @submitter.save!

    redirect_back(fallback_location: submission_path(@submitter.submission), notice: I18n.t('email_has_been_sent'))
  end
end
