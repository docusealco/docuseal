# frozen_string_literal: true

class SendSubmissionEmailController < ApplicationController
  layout 'form'

  skip_before_action :authenticate_user!
  skip_before_action :verify_authenticity_token
  skip_authorization_check

  SEND_DURATION = 30.minutes

  def create
    if params[:template_slug]
      template = Template.find_by!(slug: params[:template_slug])

      @submitter =
        Submitter.completed.where(submission: template.submissions).find_by!(email: params[:email].to_s.downcase)
    elsif params[:submission_slug]
      submission = Submission.find_by(slug: params[:submission_slug])

      if submission
        @submitter = Submitter.completed.find_by(submission: submission, email: params[:email].to_s.downcase)
      end

      return redirect_to submissions_preview_completed_path(params[:submission_slug], status: :error) unless @submitter
    else
      @submitter = Submitter.completed.find_by!(slug: params[:submitter_slug])
    end

    RateLimit.call("send-email-#{@submitter.id}", limit: 2, ttl: 5.minutes)

    SubmitterMailer.documents_copy_email(@submitter, sig: true).deliver_later! unless already_sent?(@submitter)

    respond_to do |f|
      f.html { render :success }
      f.json { head :ok }
    end
  end

  private

  def already_sent?(submitter)
    EmailEvent.exists?(tag: :submitter_documents_copy, email: submitter.email, emailable: submitter,
                       event_type: :send, created_at: SEND_DURATION.ago..Time.current)
  end
end
