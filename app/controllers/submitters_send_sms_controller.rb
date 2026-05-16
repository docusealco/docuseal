# frozen_string_literal: true

class SubmittersSendSmsController < ApplicationController
  load_and_authorize_resource :submitter

  def create
    if @submitter.phone.blank?
      return redirect_back(fallback_location: submission_path(@submitter.submission),
                           alert: I18n.t('submitter_has_no_phone_number',
                                         default: 'Submitter has no phone number.'))
    end

    unless Sms.enabled_for?(@submitter.account)
      return redirect_back(fallback_location: submission_path(@submitter.submission),
                           alert: I18n.t('sms_provider_not_configured',
                                         default: 'SMS provider is not configured.'))
    end

    if SubmissionEvent.exists?(submitter: @submitter,
                               event_type: 'send_sms',
                               created_at: 10.hours.ago..Time.current)
      return redirect_back(fallback_location: submission_path(@submitter.submission),
                           alert: I18n.t('sms_has_been_sent_already',
                                         default: 'SMS has already been sent recently.'))
    end

    SendSubmitterInvitationSmsJob.perform_async('submitter_id' => @submitter.id)

    @submitter.sent_at ||= Time.current
    @submitter.save!

    redirect_back(fallback_location: submission_path(@submitter.submission),
                  notice: I18n.t('sms_has_been_sent', default: 'SMS has been sent.'))
  end
end
