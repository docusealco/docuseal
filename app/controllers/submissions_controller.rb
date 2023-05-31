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
    emails = params[:emails].to_s.scan(User::EMAIL_REGEXP)

    submissions =
      emails.map do |email|
        submission = @template.submissions.create!(email:, sent_at: params[:send_email] == '1' ? Time.current : nil)

        if params[:send_email] == '1'
          SubmissionMailer.invitation_email(submission, message: params[:message]).deliver_later!
        end

        submission
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

  def load_template
    @template = current_account.templates.find(params[:template_id])
  end
end
