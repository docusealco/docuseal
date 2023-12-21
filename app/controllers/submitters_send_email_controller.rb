# frozen_string_literal: true

class SubmittersSendEmailController < ApplicationController
  load_and_authorize_resource :submitter, id_param: :submitter_slug, find_by: :slug

  def create
    if Docuseal.multitenant? && SubmissionEvent.exists?(submitter: @submitter,
                                                        event_type: 'send_email',
                                                        created_at: 24.hours.ago..Time.current)
      return redirect_back(fallback_location: submission_path(@submitter.submission),
                           alert: 'Email has been sent already.')
    end

    SubmitterMailer.invitation_email(@submitter).deliver_later!

    SubmissionEvent.create!(submitter: @submitter, event_type: 'send_email')

    @submitter.sent_at ||= Time.current
    @submitter.save!

    redirect_back(fallback_location: submission_path(@submitter.submission), notice: 'Email has been sent')
  end
end
