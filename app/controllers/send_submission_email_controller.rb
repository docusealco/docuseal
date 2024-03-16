# frozen_string_literal: true

class SendSubmissionEmailController < ApplicationController
  layout 'form'

  skip_before_action :authenticate_user!
  skip_before_action :verify_authenticity_token
  skip_authorization_check

  def success; end

  def create
    @submitter =
      if params[:template_slug]
        Submitter.joins(submission: :template).find_by!(email: params[:email].to_s.downcase,
                                                        template: { slug: params[:template_slug] })
      elsif params[:submission_slug]
        Submitter.joins(:submission).find_by!(email: params[:email].to_s.downcase,
                                              submission: { slug: params[:submission_slug] })
      else
        Submitter.find_by!(slug: params[:submitter_slug])
      end

    RateLimit.call("send-email-#{@submitter.id}", limit: 2, ttl: 5.minutes)

    SubmitterMailer.documents_copy_email(@submitter, sig: true).deliver_later!

    respond_to do |f|
      f.html { redirect_to success_send_submission_email_index_path }
      f.json { head :ok }
    end
  end
end
