# frozen_string_literal: true

module Api
  class SubmissionEventsController < ApiBaseController
    load_and_authorize_resource :submission, parent: false

    def index
      submissions = @submissions.active.where.not(completed_at: nil)

      params[:after] = Time.zone.at(params[:after].to_i) if params[:after].present?
      params[:before] = Time.zone.at(params[:before].to_i) if params[:before].present?

      submissions = paginate(submissions.preload(
                               :created_by_user, :submission_events,
                               template: :folder,
                               submitters: { documents_attachments: :blob, attachments_attachments: :blob },
                               audit_trail_attachment: :blob,
                               combined_document_attachment: :blob
                             ),
                             field: :completed_at)

      expires_at = Accounts.link_expires_at(current_account)

      render json: {
        data: submissions.map do |s|
                {
                  event_type: 'submission.completed',
                  timestamp: s.completed_at,
                  data: Submissions::SerializeForApi.call(s, s.submitters, expires_at:)
                }
              end,
        pagination: {
          count: submissions.size,
          next: submissions.last&.completed_at&.to_i,
          prev: submissions.first&.completed_at&.to_i
        }
      }
    end
  end
end
