# frozen_string_literal: true

class SubmissionsController < ApplicationController
  before_action :load_template, only: %i[index new create]

  def index
    @submissions = @template.submissions.active
  end

  def show
    @submission =
      Submission.joins(:template).where(template: { account_id: current_account.id })
                .preload(template: { documents_attachments: { preview_images_attachments: :blob } })
                .find(params[:id])
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

    redirect_to template_submissions_path(@template), notice: "#{submissions.size} recepients added"
  end

  def destroy
    submission = Submission.joins(:template).where(template: { account_id: current_account.id })
                           .find(params[:id])

    submission.update!(deleted_at: Time.current)

    redirect_to template_submissions_path(submission.template), notice: 'Submission has been archieved'
  end

  private

  def create_submissions_from_emails
    emails = params[:emails].to_s.scan(User::EMAIL_REGEXP)

    emails.map do |email|
      submission = @template.submissions.new
      submission.submitters.new(email:, uuid: @template.submitters.first['uuid'],
                                sent_at: params[:send_email] == '1' ? Time.current : nil)

      submission.tap(&:save!)
    end
  end

  def create_submissions_from_submitters
    submissions_params[:submission].to_h.map do |_, attrs|
      submission = @template.submissions.new

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
