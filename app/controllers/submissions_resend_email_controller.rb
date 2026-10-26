# frozen_string_literal: true

class SubmissionsResendEmailController < ApplicationController
  load_and_authorize_resource :submission

  before_action do
    authorize!(:manage, :resend_all)
    authorize!(:update, @submission)
  end

  def create
    submitters = @submission.submitters.reject(&:completed_at?).select { |s| s.email.present? && !s.declined_at? }

    if Docuseal.multitenant?
      recent_submitter_ids =
        SubmissionEvent.where(submitter_id: submitters.map(&:id),
                              event_type: 'send_email',
                              created_at: 10.hours.ago..Time.current).pluck(:submitter_id).to_set

      submitters = submitters.reject { |s| recent_submitter_ids.include?(s.id) }
    end

    submitters.each do |submitter|
      SendSubmitterInvitationEmailJob.perform_async('submitter_id' => submitter.id)

      submitter.sent_at ||= Time.current
      submitter.save!
    end

    notice =
      if submitters.empty?
        I18n.t('email_has_been_sent_already')
      else
        I18n.t('emails_have_been_sent_to_n_recipients', count: submitters.size)
      end

    redirect_back(fallback_location: submission_path(@submission), notice:)
  end
end
