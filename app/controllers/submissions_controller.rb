# frozen_string_literal: true

class SubmissionsController < ApplicationController
  before_action :load_template, only: %i[new create]
  authorize_resource :template, only: %i[new create]

  load_and_authorize_resource :submission, only: %i[show destroy]

  prepend_before_action :maybe_redirect_com, only: %i[show]

  before_action only: :create do
    authorize!(:create, Submission)
  end

  def show
    @submission = Submissions.preload_with_pages(@submission)

    unless @submission.submitters.all?(&:completed_at?)
      ActiveRecord::Associations::Preloader.new(
        records: [@submission],
        associations: [submitters: :start_form_submission_events]
      ).call
    end

    render :show, layout: 'plain'
  end

  def new
    authorize!(:new, Submission)
  end

  def create
    save_template_message(@template, params) if params[:save_message] == '1'

    if params[:is_custom_message] != '1'
      params.delete(:subject)
      params.delete(:body)
    end

    submissions =
      if params[:emails].present?
        Submissions.create_from_emails(template: @template,
                                       user: current_user,
                                       source: :invite,
                                       mark_as_sent: params[:send_email] == '1',
                                       emails: params[:emails],
                                       params: params.merge('send_completed_email' => true))
      else
        Submissions.create_from_submitters(template: @template,
                                           user: current_user,
                                           source: :invite,
                                           submitters_order: params[:preserve_order] == '1' ? 'preserved' : 'random',
                                           submissions_attrs: submissions_params[:submission].to_h.values,
                                           params: params.merge('send_completed_email' => true))
      end

    WebhookUrls.enqueue_events(submissions, 'submission.created')

    Submissions.send_signature_requests(submissions)

    SearchEntries.enqueue_reindex(submissions)

    redirect_to template_path(@template), notice: I18n.t('new_recipients_have_been_added')
  rescue Submissions::CreateFromSubmitters::BaseError => e
    render turbo_stream: turbo_stream.replace(:submitters_error,
                                              partial: 'submissions/error',
                                              locals: { error: e.message }),
           status: :unprocessable_entity
  end

  def destroy
    notice =
      if params[:permanently].in?(['true', true])
        @submission.destroy!

        I18n.t('submission_has_been_removed')
      else
        @submission.update!(archived_at: Time.current)

        WebhookUrls.enqueue_events(@submission, 'submission.archived')

        I18n.t('submission_has_been_archived')
      end

    redirect_back(fallback_location: @submission.template_id ? template_path(@submission.template) : root_path, notice:)
  end

  private

  def save_template_message(template, params)
    template.preferences['request_email_subject'] = params[:subject] if params[:subject].present?
    template.preferences['request_email_body'] = params[:body] if params[:body].present?

    template.save!
  end

  def submissions_params
    params.permit(submission: { submitters: [%i[uuid email phone name]] })
  end

  def load_template
    @template = Template.accessible_by(current_ability).find(params[:template_id])
  end
end
