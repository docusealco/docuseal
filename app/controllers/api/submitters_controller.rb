# frozen_string_literal: true

module Api
  class SubmittersController < ApiBaseController
    load_and_authorize_resource :submitter

    def index
      submitters = Submitters.search(@submitters, params[:q])

      submitters = submitters.where(external_id: params[:application_key]) if params[:application_key].present?
      submitters = submitters.where(external_id: params[:external_id]) if params[:external_id].present?
      submitters = submitters.where(submission_id: params[:submission_id]) if params[:submission_id].present?

      if params[:template_id].present?
        submitters = submitters.joins(:submission).where(submission: { template_id: params[:template_id] })
      end

      submitters = maybe_filder_by_completed_at(submitters, params)

      submitters = paginate(
        submitters.preload(:template, :submission, :submission_events,
                           documents_attachments: :blob, attachments_attachments: :blob)
      )

      render json: {
        data: submitters.map do |s|
                Submitters::SerializeForApi.call(s, with_template: true, with_events: true, params:)
              end,
        pagination: {
          count: submitters.size,
          next: submitters.last&.id,
          prev: submitters.first&.id
        }
      }
    end

    def show
      Submissions::EnsureResultGenerated.call(@submitter) if @submitter.completed_at?

      render json: Submitters::SerializeForApi.call(@submitter, with_template: true, with_events: true, params:)
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
                                                                  default_submitter_uuid: @submitter.uuid)

      assign_submitter_attrs(@submitter, normalized_params)

      ApplicationRecord.transaction do
        Submissions::NormalizeParamUtils.save_default_value_attachments!(new_attachments, [@submitter])

        @submitter.save!

        @submitter.submission.save!

        SubmissionEvents.create_with_tracking_data(@submitter, 'api_complete_form', request) if @submitter.completed_at?
      end

      if @submitter.completed_at?
        ProcessSubmitterCompletionJob.perform_async({ 'submitter_id' => @submitter.id })
      elsif normalized_params[:send_email] || normalized_params[:send_sms]
        Submitters.send_signature_requests([@submitter])
      end

      render json: Submitters::SerializeForApi.call(@submitter, with_template: false,
                                                                with_urls: true,
                                                                with_events: false,
                                                                params:)
    end

    def submitter_params
      submitter_params = params.key?(:submitter) ? params.require(:submitter) : params

      submitter_params.permit(
        :send_email, :send_sms, :reply_to, :completed_redirect_url, :uuid, :name, :email, :role,
        :completed, :phone, :application_key, :external_id, :go_to_last,
        { metadata: {}, values: {}, readonly_fields: [], message: %i[subject body],
          fields: [[:name, :uuid, :default_value, :value,
                    :readonly, :redacted, :validation_pattern, :invalid_message,
                    { default_value: [], value: [], preferences: {} }]] }
      )
    end

    private

    def maybe_filder_by_completed_at(submitters, params)
      if params[:completed_after].present?
        submitters = submitters.where(completed_at: Time.zone.parse(params[:completed_after])..)
      end

      if params[:completed_before].present?
        submitters = submitters.where(completed_at: ..Time.zone.parse(params[:completed_before]))
      end

      submitters
    end

    def assign_submitter_attrs(submitter, attrs)
      values = attrs[:values]&.to_unsafe_h || {}

      assign_submission_fields(submitter.submission)

      phone_field_uuid = submitter.submission.template_fields.find do |f|
        values[f['uuid']].present? && f['type'] == 'phone'
      end&.dig('uuid')

      submitter.email = Submissions.normalize_email(attrs[:email]) if attrs.key?(:email)

      if attrs.key?(:phone)
        submitter.phone = attrs[:phone].to_s.gsub(/[^0-9+]/, '')
      elsif values[phone_field_uuid].present?
        submitter.phone = values[phone_field_uuid].to_s.gsub(/[^0-9+]/, '')
      end

      values = values.except(phone_field_uuid)

      submitter.values = submitter.values.merge(values) if values.present?
      submitter.metadata = attrs[:metadata] if attrs.key?(:metadata)

      maybe_assign_completed_attributes(submitter, attrs)

      assign_external_id(submitter, attrs)
      assign_preferences(submitter, attrs)

      submitter
    end

    def maybe_assign_completed_attributes(submitter, attrs)
      submitter.completed_at = attrs[:completed] ? Time.current : submitter.completed_at

      if attrs[:completed]
        submitter.values = Submitters::SubmitValues.merge_default_values(submitter)
        submitter.values = Submitters::SubmitValues.merge_formula_values(submitter)
        submitter.values = Submitters::SubmitValues.maybe_remove_condition_values(submitter)

        submitter.values = submitter.values.transform_values do |v|
          v == '{{date}}' ? Time.current.in_time_zone(submitter.account.timezone).to_date.to_s : v
        end
      end

      submitter
    end

    def assign_external_id(submitter, attrs)
      submitter.external_id = attrs[:application_key] if attrs.key?(:application_key)
      submitter.external_id = attrs[:external_id] if attrs.key?(:external_id)

      submitter
    end

    def assign_submission_fields(submission)
      submission.template_fields ||= submission.template.fields
      submission.template_schema ||= submission.template.schema
    end

    def assign_preferences(submitter, attrs)
      submitter_preferences = Submitters.normalize_preferences(submitter.account, current_user, attrs)

      submitter.preferences['default_values'] = attrs[:values].to_unsafe_h if attrs[:values].present?

      if submitter_preferences.key?('send_email')
        submitter.preferences['send_email'] = submitter_preferences['send_email']
      end

      submitter.preferences['send_sms'] = submitter_preferences['send_sms'] if submitter_preferences.key?('send_sms')
      submitter.preferences['reply_to'] = submitter_preferences['reply_to'] if submitter_preferences.key?('reply_to')
      if submitter_preferences.key?('go_to_last')
        submitter.preferences['go_to_last'] = submitter_preferences['go_to_last']
      end

      if submitter_preferences.key?('completed_redirect_url')
        submitter.preferences['completed_redirect_url'] = submitter_preferences['completed_redirect_url']
      end

      return unless submitter_preferences.key?('email_message_uuid')

      submitter.preferences['email_message_uuid'] = submitter_preferences['email_message_uuid']

      submitter
    end
  end
end
