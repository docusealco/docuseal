# frozen_string_literal: true

class SendSubmissionEmailController < ApplicationController
  layout 'form'

  skip_before_action :authenticate_user!
  skip_before_action :verify_authenticity_token

  def success; end

  def create
    @submitter =
      if params[:template_slug]
        Submitter.joins(submission: :template).find_by!(email: params[:email],
                                                        template: { slug: params[:template_slug] })
      else
        Submitter.find_by!(slug: params[:submitter_slug])
      end

    Submissions::GenerateResultAttachments.call(@submitter) if @submitter.documents.blank?

    SubmitterMailer.documents_copy_email(@submitter).deliver_later!

    respond_to do |f|
      f.html { redirect_to success_send_submission_email_index_path }
      f.json { head :ok }
    end
  end
end
