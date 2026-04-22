# frozen_string_literal: true

class TemplatesQuickSendController < ApplicationController
  load_and_authorize_resource :template

  before_action :authorize_create_submission, only: :create

  def show
    @fields = @template.fields
    @submitters = @template.submitters
  end

  def create
    submissions =
      Submissions.create_from_emails(template: @template,
                                     user: current_user,
                                     source: :invite,
                                     mark_as_sent: true,
                                     emails: params[:email],
                                     params: { 'send_completed_email' => true })

    WebhookUrls.enqueue_events(submissions, 'submission.created')

    Submissions.send_signature_requests(submissions)

    SearchEntries.enqueue_reindex(submissions)

    redirect_to template_path(@template), notice: I18n.t('submission_has_been_sent')
  rescue Submissions::CreateFromSubmitters::BaseError => e
    redirect_to template_path(@template), alert: e.message
  end

  private

  def authorize_create_submission
    authorize!(:create, Submission)
  end
end
