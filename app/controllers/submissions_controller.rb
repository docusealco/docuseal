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
        create_submissions_from_emails
      else
        create_submissions_from_submitters
      end

    if params[:send_email] == '1'
      submissions.flat_map(&:submitters).each do |submitter|
        SubmitterMailer.invitation_email(submitter, message: params[:message]).deliver_later!
      end
    end

    redirect_to template_path(@template),
                notice: "#{submissions.size} #{'recipient'.pluralize(submissions.size)} added"
  end

  def destroy
    submission = Submission.joins(:template).where(template: { account_id: current_account.id })
                           .find(params[:id])

    submission.update!(deleted_at: Time.current)

    redirect_back(fallback_location: template_path(submission.template), notice: 'Submission has been archived')
  end

  private

  def create_submissions_from_emails
    emails = params[:emails].to_s.scan(User::EMAIL_REGEXP)

    emails.map do |email|
      submission = @template.submissions.new(created_by_user: current_user)
      submission.submitters.new(email:, uuid: @template.submitters.first['uuid'],
                                sent_at: params[:send_email] == '1' ? Time.current : nil)

      submission.tap(&:save!)
    end
  end

  def create_submissions_from_submitters
    submissions_params[:submission].to_h.map do |_, attrs|
      submission = @template.submissions.new(created_by_user: current_user)

      attrs[:submitters].each do |submitter_attrs|
        submission.submitters.new(**submitter_attrs, sent_at: params[:send_email] == '1' ? Time.current : nil)
      end

      submission.tap(&:save!)
    end
  end

  def submissions_params
    params.permit(submission: { submitters: [%i[uuid email]] })
  end

  def load_template
    @template = current_account.templates.find(params[:template_id])
  end
end
