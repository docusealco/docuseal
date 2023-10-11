# frozen_string_literal: true

module Api
  class SubmissionsController < ApiBaseController
    load_and_authorize_resource :template, only: :create
    load_and_authorize_resource :submission, only: %i[show index]

    before_action only: :create do
      authorize!(:create, Submission)
    end

    def index
      submissions = Submissions.search(@submissions, params[:q])
      submissions = submissions.where(template_id: params[:template_id]) if params[:template_id].present?

      submissions = paginate(submissions.preload(:created_by_user, :template, :submitters))

      render json: {
        data: submissions.as_json(serialize_params),
        pagination: {
          count: submissions.size,
          next: submissions.last&.id,
          prev: submissions.first&.id
        }
      }
    end

    def show
      serialized_subbmitters =
        @submission.submitters.preload(documents_attachments: :blob, attachments_attachments: :blob).map do |submitter|
          Submissions::EnsureResultGenerated.call(submitter) if submitter.completed_at?

          Submitters::SerializeForApi.call(submitter)
        end

      json = @submission.as_json(
        serialize_params.deep_merge(
          include: {
            submission_events: {
              only: %i[id submitter_id event_type event_timestamp]
            }
          }
        )
      )

      json[:submitters] = serialized_subbmitters

      render json:
    end

    def create
      is_send_email = !params[:send_email].in?(['false', false])

      submissions =
        if (emails = (params[:emails] || params[:email]).presence) && params[:submission].blank?
          Submissions.create_from_emails(template: @template,
                                         user: current_user,
                                         source: :api,
                                         mark_as_sent: is_send_email,
                                         emails:)
        else
          submissions_attrs, attachments = normalize_submissions_params!(submissions_params[:submission], @template)

          Submissions.create_from_submitters(
            template: @template,
            user: current_user,
            source: :api,
            mark_as_sent: is_send_email,
            submitters_order: params[:submitters_order] || 'preserved',
            submissions_attrs:
          )
        end

      Submissions.send_signature_requests(submissions, send_email: is_send_email)

      submitters = submissions.flat_map(&:submitters)

      save_default_value_attachments!(attachments, submitters)

      render json: submitters
    rescue Submitters::NormalizeValues::UnknownFieldName, Submitters::NormalizeValues::UnknownSubmitterName => e
      render json: { error: e.message }, status: :unprocessable_entity
    end

    def destroy
      @submission.update!(deleted_at: Time.current)

      render json: @submission.as_json(only: %i[id deleted_at])
    end

    private

    def serialize_params
      {
        only: %i[id source submitters_order created_at updated_at],
        include: {
          submitters: { only: %i[id slug uuid name email phone
                                 completed_at opened_at sent_at
                                 created_at updated_at],
                        methods: %i[status] },
          template: { only: %i[id name created_at updated_at] },
          created_by_user: { only: %i[id email first_name last_name] }
        }
      }
    end

    def submissions_params
      params.permit(submission: [{
                      submitters: [[:uuid, :name, :email, :role, :completed, :phone,
                                    { values: {}, readonly_fields: [] }]]
                    }])
    end

    def normalize_submissions_params!(submissions_params, template)
      attachments = []

      Array.wrap(submissions_params).each do |submission|
        submission[:submitters].each_with_index do |submitter, index|
          next if submitter[:values].blank?

          values, new_attachments =
            Submitters::NormalizeValues.call(template,
                                             submitter[:values],
                                             submitter[:role] || template.submitters[index]['name'])

          attachments.push(*new_attachments)

          submitter[:values] = values
        end
      end

      [submissions_params, attachments]
    end

    def save_default_value_attachments!(attachments, submitters)
      return if attachments.blank?

      attachments_index = attachments.index_by(&:uuid)

      submitters.each do |submitter|
        submitter.values.to_a.each do |_, value|
          attachment = attachments_index[value]

          next unless attachment

          attachment.record = submitter

          attachment.save!
        end
      end
    end
  end
end
