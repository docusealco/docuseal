# frozen_string_literal: true

class SubmissionsController < ApplicationController
  before_action :load_template, only: %i[new create]
  authorize_resource :template, only: %i[new create]

  load_and_authorize_resource :submission, only: %i[show destroy]

  def show
    ActiveRecord::Associations::Preloader.new(
      records: [@submission],
      associations: [:template, { template_schema_documents: [:blob, { preview_images_attachments: :blob }] }]
    ).call

    render :show, layout: 'plain'
  end

  def new
    authorize!(:new, Submission)
  end

  def create
    authorize!(:create, Submission)

    submissions =
      if params[:emails].present?
        Submissions.create_from_emails(template: @template,
                                       user: current_user,
                                       source: :invite,
                                       mark_as_sent: params[:send_email] == '1',
                                       emails: params[:emails])
      else
        Submissions.create_from_submitters(template: @template,
                                           user: current_user,
                                           source: :invite,
                                           submitters_order: params[:preserve_order] == '1' ? 'preserved' : 'random',
                                           mark_as_sent: params[:send_email] == '1',
                                           submissions_attrs: submissions_params[:submission].to_h.values)
      end

    Submissions.send_signature_requests(submissions, params)

    redirect_to template_path(@template), notice: 'New recipients have been added'
  end

  def destroy
    @submission.update!(deleted_at: Time.current)

    redirect_back(fallback_location: template_path(@submission.template), notice: 'Submission has been archived')
  end

  private

  def submissions_params
    params.permit(submission: { submitters: [%i[uuid email phone name]] })
  end

  def load_template
    @template = current_account.templates.find(params[:template_id])
  end
end
