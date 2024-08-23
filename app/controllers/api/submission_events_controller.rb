# frozen_string_literal: true

module Api
  class SubmissionEventsController < ApiBaseController
    load_and_authorize_resource :submission, parent: false

    def index
      submissions = build_completed_query(@submissions)

      params[:after] = Time.zone.at(params[:after].to_i) if params[:after].present?
      params[:before] = Time.zone.at(params[:before].to_i) if params[:before].present?

      submissions = paginate(submissions.preload(
                               :created_by_user, :submission_events,
                               template: :folder,
                               submitters: { documents_attachments: :blob, attachments_attachments: :blob },
                               audit_trail_attachment: :blob
                             ),
                             field: :completed_at)

      render json: {
        data: submissions.map do |s|
                {
                  event_type: 'submission.completed',
                  timestamp: s.completed_at,
                  data: Submissions::SerializeForApi.call(s, s.submitters)
                }
              end,
        pagination: {
          count: submissions.size,
          next: submissions.last&.completed_at&.to_i,
          prev: submissions.first&.completed_at&.to_i
        }
      }
    end

    private

    def build_completed_query(submissions)
      submissions = submissions.where(
        Submitter.where(completed_at: nil).where(
          Submitter.arel_table[:submission_id].eq(Submission.arel_table[:id])
        ).select(1).arel.exists.not
      )

      submissions.joins(:submitters)
                 .group(:id)
                 .select(Submission.arel_table[Arel.star],
                         Submitter.arel_table[:completed_at].maximum.as('completed_at'))
    end
  end
end
