# frozen_string_literal: true

module Submitters
  module SubmitValues
    ValidationError = Class.new(StandardError)

    VARIABLE_REGEXP = /\{\{?(\w+)\}\}?/

    module_function

    def call(submitter, params, request)
      Submissions.update_template_fields!(submitter.submission) if submitter.submission.template_fields.blank?

      unless submitter.submission_events.exists?(event_type: 'start_form')
        SubmissionEvents.create_with_tracking_data(submitter, 'start_form', request)

        SendFormStartedWebhookRequestJob.perform_async({ 'submitter_id' => submitter.id })
      end

      update_submitter!(submitter, params, request)

      submitter.submission.save!

      ProcessSubmitterCompletionJob.perform_async({ 'submitter_id' => submitter.id }) if submitter.completed_at?

      submitter
    end

    def update_submitter!(submitter, params, request)
      values = normalized_values(params)

      submitter.values.merge!(values)
      submitter.opened_at ||= Time.current

      assign_completed_attributes(submitter, request) if params[:completed] == 'true'

      ApplicationRecord.transaction do
        validate_values!(values, submitter, params, request)

        SubmissionEvents.create_with_tracking_data(submitter, 'complete_form', request) if params[:completed] == 'true'

        submitter.save!
      end

      submitter
    end

    def assign_completed_attributes(submitter, request)
      submitter.completed_at = Time.current
      submitter.ip = request.remote_ip
      submitter.ua = request.user_agent
      submitter.values = merge_default_values(submitter)
      submitter.values = merge_formula_values(submitter)
      submitter.values = maybe_remove_condition_values(submitter)
      submitter.values = submitter.values.transform_values do |v|
        v == '{{date}}' ? Time.current.in_time_zone(submitter.account.timezone).to_date.to_s : v
      end

      submitter
    end

    def normalized_values(params)
      params.fetch(:values, {}).to_unsafe_h.transform_values do |v|
        if params[:cast_boolean] == 'true'
          v == 'true'
        elsif params[:cast_number] == 'true'
          (v.to_f % 1).zero? ? v.to_i : v.to_f
        elsif params[:normalize_phone] == 'true'
          v.to_s.gsub(/[^0-9+]/, '')
        else
          v.is_a?(Array) ? v.compact_blank : v
        end
      end
    end

    def validate_values!(values, submitter, params, request)
      values.each do |key, value|
        field = submitter.submission.template_fields.find { |e| e['uuid'] == key }

        validate_value!(value, field, params, submitter, request)
      end
    end

    def merge_default_values(submitter)
      default_values = submitter.submission.template_fields.each_with_object({}) do |field, acc|
        next if field['submitter_uuid'] != submitter.uuid

        if field['type'] == 'stamp'
          acc[field['uuid']] ||=
            Submitters::CreateStampAttachment.build_attachment(
              submitter,
              with_logo: field.dig('preferences', 'with_logo') != false
            ).uuid

          next
        end

        value = field['default_value']

        next if value.blank?

        acc[field['uuid']] = template_default_value_for_submitter(value, submitter, with_time: true)
      end

      default_values.compact_blank.merge(submitter.values)
    end

    def merge_formula_values(submitter)
      computed_values = submitter.submission.template_fields.each_with_object({}) do |field, acc|
        next if field['submitter_uuid'] != submitter.uuid

        formula = field.dig('preferences', 'formula')

        next if formula.blank?

        acc[field['uuid']] = calculate_formula_value(formula, submitter.values.merge(acc.compact_blank))
      end

      submitter.values.merge(computed_values.compact_blank)
    end

    def calculate_formula_value(_formula, _values)
      0
    end

    def template_default_value_for_submitter(value, submitter, with_time: false)
      return if value.blank?
      return if submitter.blank?

      role = submitter.submission.template_submitters.find { |e| e['uuid'] == submitter.uuid }['name']

      replace_default_variables(value,
                                submitter.attributes.merge('role' => role),
                                submitter.submission,
                                with_time:)
    end

    def maybe_remove_condition_values(submitter)
      fields_uuid_index = submitter.submission.template_fields.index_by { |e| e['uuid'] }

      submitter.submission.template_fields.each do |field|
        next if field['submitter_uuid'] != submitter.uuid

        submitter.values.delete(field['uuid']) unless check_field_condition(submitter, field, fields_uuid_index)
      end

      submitter.values
    end

    def check_field_condition(submitter, field, fields_uuid_index)
      return true if field['conditions'].blank?

      submitter_values = submitter.values

      field['conditions'].reduce(true) do |acc, c|
        case c['action']
        when 'empty', 'unchecked'
          acc && submitter_values[c['field_uuid']].blank?
        when 'not_empty', 'checked'
          acc && submitter_values[c['field_uuid']].present?
        when 'equal', 'contains'
          field = fields_uuid_index[c['field_uuid']]
          option = field['options'].find { |o| o['uuid'] == c['value'] }
          values = Array.wrap(submitter_values[c['field_uuid']])

          acc && values.include?(option['value'].presence || "Option #{field['options'].index(option)}")
        when 'not_equal', 'does_not_contain'
          field = fields_uuid_index[c['field_uuid']]
          option = field['options'].find { |o| o['uuid'] == c['value'] }
          values = Array.wrap(submitter_values[c['field_uuid']])

          acc && values.exclude?(option['value'].presence || "Option #{field['options'].index(option)}")
        else
          acc
        end
      end
    end

    def replace_default_variables(value, attrs, submission, with_time: false)
      return value if value.in?([true, false])
      return if value.blank?

      value.to_s.gsub(VARIABLE_REGEXP) do |e|
        case key = ::Regexp.last_match(1)
        when 'id'
          attrs['submission_id']
        when 'time'
          if with_time
            I18n.l(Time.current.in_time_zone(submission.account.timezone),
                   format: :long, locale: submission.account.locale)
          else
            e
          end
        when 'date'
          if with_time
            I18n.l(Time.current.in_time_zone(submission.account.timezone).to_date)
          else
            e
          end
        when 'role', 'email', 'phone', 'name'
          attrs[key] || e
        else
          e
        end
      end
    end

    def validate_value!(_value, _field, _params, _submitter, _request)
      true
    end
  end
end
