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

    def update
      if @submitter.completed_at?
        return render json: { error: 'Submitter has already completed the submission.' }, status: :unprocessable_entity
      end

      role = @submitter.submission.template_submitters.find { |e| e['uuid'] == @submitter.uuid }['name']

      normalized_params, new_attachments =
        Submissions::NormalizeParamUtils.normalize_submitter_params!(submitter_params.merge(role:), @submitter.template,
                                                                     for_submitter: @submitter)

      Submissions::CreateFromSubmitters.maybe_set_template_fields(@submitter.submission,
                                                                  [normalized_params],
                                                                  submitter_uuid: @submitter.uuid)

      assign_submitter_attrs(@submitter, normalized_params)

      ApplicationRecord.transaction do
        Submissions::NormalizeParamUtils.save_default_value_attachments!(new_attachments, [@submitter])

        @submitter.save!

        @submitter.submission.save!
      end

      if @submitter.completed_at?
        ProcessSubmitterCompletionJob.perform_later(@submitter)
      elsif normalized_params[:send_email] || normalized_params[:send_sms]
        Submitters.send_signature_requests([@submitter])
      end

      render json: Submitters::SerializeForApi.call(@submitter, with_template: false, with_events: false)
    end

    def submitter_params
      submitter_params = params.key?(:submitter) ? params.require(:submitter) : params

      submitter_params.permit(
        :send_email, :send_sms, :uuid, :name, :email, :role, :completed, :phone, :application_key,
        { values: {}, readonly_fields: [], message: %i[subject body],
          fields: [%i[name default_value readonly validation_pattern invalid_message]] }
      )
    end

    private

    def assign_submitter_attrs(submitter, attrs)
      submitter.email = Submissions.normalize_email(attrs[:email]) if attrs.key?(:email)
      submitter.phone = attrs[:phone].to_s.gsub(/[^0-9+]/, '') if attrs.key?(:phone)
      submitter.values = submitter.values.merge(attrs[:values].to_unsafe_h) if attrs[:values]
      submitter.completed_at = attrs[:completed] ? Time.current : submitter.completed_at
      submitter.application_key = attrs[:application_key] if attrs.key?(:application_key)

      assign_preferences(submitter, attrs)

      submitter
    end

    def assign_preferences(submitter, attrs)
      submitter_preferences = Submitters.normalize_preferences(submitter.account, current_user, attrs)

      if submitter_preferences.key?('send_email')
        submitter.preferences['send_email'] = submitter_preferences['send_email']
      end

      submitter.preferences['send_sms'] = submitter_preferences['send_sms'] if submitter_preferences.key?('send_sms')

      return unless submitter_preferences.key?('email_message_uuid')

      submitter.preferences['email_message_uuid'] = submitter_preferences['email_message_uuid']

      submitter
    end
  end
end
