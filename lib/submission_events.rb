# frozen_string_literal: true

module SubmissionEvents
  TRACKING_PARAM_LENGTH = 6

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
