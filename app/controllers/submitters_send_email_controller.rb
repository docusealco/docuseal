# frozen_string_literal: true

class SubmittersSendEmailController < ApplicationController
  def create
    submitter = Submitter.joins(:template)
                         .where(template: { account_id: current_account.id })
                         .find_by!(slug: params[:submitter_slug])

    SubmitterMailer.invitation_email(submitter).deliver_later!

    submitter.sent_at ||= Time.current
    submitter.save!

    redirect_back(fallback_location: submission_path(submitter.submission), notice: 'Email has been sent')
  end
end
