# frozen_string_literal: true

module SubmissionEvents
  TRACKING_PARAM_LENGTH = 6

  EVENT_NAMES = {
    send_email: 'Email sent',
    send_reminder_email: 'Reminder email sent',
    send_sms: 'SMS sent',
    send_2fa_sms: 'Verification SMS sent',
    open_email: 'Email opened',
    click_email: 'Email link clicked',
    click_sms: 'SMS link clicked',
    phone_verified: 'Phone verified',
    start_form: 'Submission started',
    view_form: 'Form viewed',
    complete_form: 'Submission completed',
    api_complete_form: 'Submission completed via API'
  }.freeze

  module_function

  def build_tracking_param(submitter, event_type = 'click_email')
    Base64.urlsafe_encode64(
      Digest::SHA1.digest([submitter.slug, event_type, Rails.application.secret_key_base].join(':'))
    ).first(TRACKING_PARAM_LENGTH)
  end

  def create_with_tracking_data(submitter, event_type, request, data = {})
    SubmissionEvent.create!(submitter:, event_type:, data: {
      ip: request.remote_ip,
      ua: request.user_agent,
      sid: request.session.id.to_s,
      uid: request.env['warden'].user(:user)&.id,
      **data
    }.compact_blank)
  end
end
