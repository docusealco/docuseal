# frozen_string_literal: true

class SubmissionsController < ApplicationController
  before_action :load_template, only: %i[new create]
  authorize_resource :template, only: %i[new create]

  load_and_authorize_resource :submission, only: %i[show destroy]

  def show
    @submission = Submissions.preload_with_pages(@submission)

    render :show, layout: 'plain'
  end

  def new
    authorize!(:new, Submission)
  end

  def create
    authorize!(:create, Submission)

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

    submissions.each do |submission|
      SendSubmissionCreatedWebhookRequestJob.perform_async({ 'submission_id' => submission.id })
    end

    Submissions.send_signature_requests(submissions)

    redirect_to template_path(@template), notice: 'New recipients have been added'
  end

  def destroy
    notice =
      if params[:permanently].present?
        @submission.destroy!

        'Submission has been removed'
      else
        @submission.update!(archived_at: Time.current)

        SendSubmissionArchivedWebhookRequestJob.perform_async('submission_id' => @submission.id)

        'Submission has been archived'
      end

    redirect_back(fallback_location: template_path(@submission.template), notice:)
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
