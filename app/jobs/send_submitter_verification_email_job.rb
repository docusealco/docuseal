# frozen_string_literal: true

class SendSubmitterVerificationEmailJob
  include Sidekiq::Job

  def perform(params = {})
    submitter = Submitter.find(params['submitter_id'])

    SubmitterMailer.otp_verification_email(submitter).deliver_now!

    SubmissionEvent.create!(submitter_id: params['submitter_id'],
                            event_type: 'send_2fa_email',
                            data: { email: submitter.email })
  end
end
