# frozen_string_literal: true

class SubmittersController < ApplicationController
  load_and_authorize_resource :submitter, only: %i[edit update]

  def edit
    @submitter_email_message =
      if @submitter.preferences['email_message_uuid'].present?
        @submitter.account.email_messages.find_by(uuid: @submitter.preferences['email_message_uuid'])
      end
  end

  def update
    submission = @submitter.submission

    if @submitter.submission_events.exists?(event_type: 'start_form') || submission.archived_at? || submission.expired?
      return redirect_back fallback_location: submission_path(submission), alert: I18n.t('submitter_cannot_be_updated')
    end

    if submitter_params.values.all?(&:blank?)
      return redirect_back fallback_location: submission_path(submission),
                           alert: I18n.t('at_least_one_field_must_be_filled')
    end

    if params[:is_custom_message] != '1'
      params.delete(:subject)
      params.delete(:body)
    end

    submitter_preferences = Submitters.normalize_preferences(@submitter.account, current_user, params)

    if submitter_preferences.key?('email_message_uuid')
      @submitter.preferences['email_message_uuid'] = submitter_preferences['email_message_uuid']
    end

    assign_submitter_attrs(@submitter, submitter_params)

    if @submitter.save
      maybe_resend_email_sms(@submitter, params)

      SearchEntries.enqueue_reindex(@submitter)

      redirect_back fallback_location: submission_path(submission), notice: I18n.t('changes_have_been_saved')
    else
      redirect_back fallback_location: submission_path(submission), alert: I18n.t('unable_to_save')
    end
  end

  private

  def maybe_resend_email_sms(submitter, params)
    if params[:send_email] == '1' && submitter.email.present?
      is_sent_recently = Docuseal.multitenant? &&
                         EmailEvent.exists?(email: submitter.email,
                                            tag: 'submitter_invitation',
                                            emailable: submitter,
                                            event_type: 'send',
                                            created_at: 4.hours.ago..Time.current)

      SendSubmitterInvitationEmailJob.perform_async('submitter_id' => submitter.id) unless is_sent_recently
    end

    return if submitter.phone.blank?
    return unless params[:send_sms] == '1'

    SendSubmitterInvitationSmsJob.perform_async('submitter_id' => submitter.id)
  end

  def assign_submitter_attrs(submitter, attrs)
    submitter.phone = attrs[:phone].to_s.gsub(/[^0-9+]/, '') if attrs.key?(:phone)

    submitter.email = Submissions.normalize_email(attrs[:email]) if attrs.key?(:email)

    submitter.name = attrs[:name] if attrs.key?(:name)

    submitter
  end

  def submitter_params
    params.require(:submitter).permit(:email, :name, :phone).transform_values(&:strip)
  end
end
