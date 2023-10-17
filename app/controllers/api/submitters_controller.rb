# frozen_string_literal: true

module Api
  class SubmittersController < ApiBaseController
    load_and_authorize_resource :submitter

    def index
      submitters = Submitters.search(@submitters, params[:q])

      submitters = submitters.where(application_key: params[:application_key]) if params[:application_key].present?
      submitters = submitters.where(submission_id: params[:submission_id]) if params[:submission_id].present?

      submitters = paginate(
        submitters.preload(:template, :submission, :submission_events,
                           documents_attachments: :blob, attachments_attachments: :blob)
      )

      render json: {
        data: submitters.map { |s| Submitters::SerializeForApi.call(s, with_template: true, with_events: true) },
        pagination: {
          count: submitters.size,
          next: submitters.last&.id,
          prev: submitters.first&.id
        }
      }
    end

    def show
      Submissions::EnsureResultGenerated.call(@submitter) if @submitter.completed_at?

      render json: Submitters::SerializeForApi.call(@submitter, with_template: true, with_events: true)
    end
  end
end
