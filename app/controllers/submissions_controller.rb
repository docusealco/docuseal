# frozen_string_literal: true

class SubmissionsController < ApplicationController
  before_action :load_flow, only: %i[index new create]

  def index
    @submissions = @flow.submissions.active
  end

  def show
    @submission =
      Submission.joins(:flow).where(flow: { account_id: current_account.id })
                .preload(flow: { documents_attachments: { preview_images_attachments: :blob } })
                .find(params[:id])
  end

  def new; end

  def create
    emails = params[:emails].to_s.scan(User::EMAIL_REGEXP)

    submissions =
      emails.map do |email|
        submission = @flow.submissions.create!(email:, sent_at: params[:send_email] == '1' ? Time.current : nil)

        if params[:send_email] == '1'
          SubmissionMailer.invitation_email(submission, message: params[:message]).deliver_later!
        end

        submission
      end

    redirect_to flow_submissions_path(@flow), notice: "#{submissions.size} recepients added"
  end

  def destroy
    submission = Submission.joins(:flow).where(flow: { account_id: current_account.id })
                           .find(params[:id])

    submission.update!(deleted_at: Time.current)

    redirect_to flow_submissions_path(submission.flow), notice: 'Submission has been archieved'
  end

  private

  def load_flow
    @flow = current_account.flows.find(params[:flow_id])
  end
end
