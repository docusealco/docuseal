# frozen_string_literal: true

module Api
  class SubmissionsController < ApiBaseController
    load_and_authorize_resource :template, only: :create
    load_and_authorize_resource :submission, only: %i[show index destroy]

    before_action only: :create do
      authorize!(:create, Submission)
    end

    def index
      submissions = Submissions.search(@submissions, params[:q])
      submissions = submissions.where(template_id: params[:template_id]) if params[:template_id].present?

      submissions = paginate(submissions.preload(:created_by_user, :template, :submitters,
                                                 audit_trail_attachment: :blob))

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
      params[:send_email] = true unless params.key?(:send_email)
      params[:send_sms] = false unless params.key?(:send_sms)

      submissions = create_submissions(@template, params)

      Submissions.send_signature_requests(submissions)

      render json: submissions.flat_map(&:submitters)
    rescue Submitters::NormalizeValues::UnknownFieldName, Submitters::NormalizeValues::UnknownSubmitterName => e
      render json: { error: e.message }, status: :unprocessable_entity
    end

    def destroy
      @submission.update!(deleted_at: Time.current)

      render json: @submission.as_json(only: %i[id deleted_at])
    end

    private

    def create_submissions(template, params)
      is_send_email = !params[:send_email].in?(['false', false])

      if (emails = (params[:emails] || params[:email]).presence) && params[:submission].blank?
        Submissions.create_from_emails(template:,
                                       user: current_user,
                                       source: :api,
                                       mark_as_sent: is_send_email,
                                       emails:,
                                       params:)
      else
        submissions_attrs, attachments = normalize_submissions_params!(submissions_params, template)

        submissions = Submissions.create_from_submitters(
          template:,
          user: current_user,
          source: :api,
          mark_as_sent: is_send_email,
          submitters_order: params[:submitters_order] || params[:order] || 'preserved',
          submissions_attrs:,
          params:
        )

        save_default_value_attachments!(attachments, submissions.flat_map(&:submitters))

        submissions
      end
    end

    def serialize_params
      {
        only: %i[id source submitters_order created_at updated_at],
        methods: %i[audit_log_url],
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
      key = params.key?(:submission) ? :submission : :submissions

      params.permit(
        key => [
          [:send_email, :send_sms, {
            message: %i[subject body],
            submitters: [[:send_email, :send_sms, :uuid, :name, :email, :role,
                          :completed, :phone, :application_key,
                          { values: {}, readonly_fields: [], message: %i[subject body],
                            fields: [%i[name default_value readonly validation_pattern invalid_message]] }]]
          }]
        ]
      ).fetch(key, [])
    end

    def normalize_submissions_params!(submissions_params, template)
      attachments = []

      Array.wrap(submissions_params).each do |submission|
        submission[:submitters].each_with_index do |submitter, index|
          default_values = submitter[:values] || {}

          submitter[:fields]&.each { |f| default_values[f[:name]] = f[:default_value] if f[:default_value].present? }

          next if default_values.blank?

          values, new_attachments =
            Submitters::NormalizeValues.call(template,
                                             default_values,
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
