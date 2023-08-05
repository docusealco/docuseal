# frozen_string_literal: true

class SubmissionsController < ApplicationController
  before_action :load_template, only: %i[new create]

  def show
    @submission =
      Submission.joins(:template).where(template: { account_id: current_account.id })
                .preload(template: { documents_attachments: { preview_images_attachments: :blob } })
                .find(params[:id])

    render :show, layout: 'plain'
  end

  def new; end

  def create
    submissions =
      if params[:emails].present?
        Submissions.create_from_emails(template: @template,
                                       user: current_user,
                                       source: :invite,
                                       send_email: params[:send_email] == '1',
                                       emails: params[:emails])
      else
        Submissions.create_from_submitters(template: @template,
                                           user: current_user,
                                           source: :invite,
                                           send_email: params[:send_email] == '1',
                                           submissions_attrs: submissions_params[:submission].to_h.values)
      end

    submitters = submissions.flat_map(&:submitters)

    if params[:send_email] == '1'
      submitters.each do |submitter|
        SubmitterMailer.invitation_email(submitter, message: params[:message]).deliver_later!
      end
    end

    redirect_to template_path(@template),
                notice: "#{submitters.size} #{'recipient'.pluralize(submitters.size)} added"
  end

  def destroy
    submission = Submission.joins(:template).where(template: { account_id: current_account.id })
                           .find(params[:id])

    submission.update!(deleted_at: Time.current)

    redirect_back(fallback_location: template_path(submission.template), notice: 'Submission has been archived')
  end

  private

  def submissions_params
    params.permit(submission: { submitters: [%i[uuid email]] })
  end

  def load_template
    @template = current_account.templates.find(params[:template_id])
  end
end
