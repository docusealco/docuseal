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

        WebhookUrls.for_account_id(submitter.account_id, 'form.started').each do |webhook_url|
          SendFormStartedWebhookRequestJob.perform_async('submitter_id' => submitter.id,
                                                         'webhook_url_id' => webhook_url.id)
        end
      end

      update_submitter!(submitter, params, request)

      submitter.submission.save!

      ProcessSubmitterCompletionJob.perform_async('submitter_id' => submitter.id) if submitter.completed_at?

      submitter
    end

    def update_submitter!(submitter, params, request)
      values = normalized_values(params)

      submitter.values.merge!(values)
      submitter.opened_at ||= Time.current

      assign_completed_attributes(submitter, request) if params[:completed] == 'true'

      ApplicationRecord.transaction do
        maybe_set_signature_reason!(values, submitter, params)
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
      submitter.values = maybe_remove_condition_values(submitter)
      submitter.values = merge_formula_values(submitter)
      submitter.values = submitter.values.transform_values do |v|
        v == '{{date}}' ? Time.current.in_time_zone(submitter.account.timezone).to_date.to_s : v
      end

      submitter
    end

    def maybe_set_signature_reason!(values, submitter, params)
      return if params[:with_reason].blank?

      reason_field_uuid = params[:with_reason]
      signature_field_uuid = values.except(reason_field_uuid).keys.first

      signature_field = submitter.submission.template_fields.find { |e| e['uuid'] == signature_field_uuid }

      signature_field['preferences'] ||= {}
      signature_field['preferences']['reason_field_uuid'] = reason_field_uuid

      unless submitter.submission.template_fields.find { |e| e['uuid'] == reason_field_uuid }
        reason_field = { 'type' => 'text',
                         'uuid' => reason_field_uuid,
                         'name' => I18n.t(:reason),
                         'readonly' => true,
                         'submitter_uuid' => submitter.uuid }

        submitter.submission.template_fields.insert(submitter.submission.template_fields.index(signature_field) + 1,
                                                    reason_field)
      end

      submitter.submission.save!
    end

    def normalized_values(params)
      params.fetch(:values, {}).to_unsafe_h.transform_values do |v|
        if params[:cast_boolean] == 'true'
          v == 'true'
        elsif params[:cast_number] == 'true'
          if v == ''
            nil
          else
            (v.to_f % 1).zero? ? v.to_i : v.to_f
          end
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

        if field['type'] == 'verification'
          acc[field['uuid']] =
            if submitter.submission_events.exists?(event_type: :complete_verification)
              I18n.t(:verified, locale: :en)
            elsif field['required']
              raise ValidationError, 'ID Not Verified'
            end

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
        next if field['type'] == 'payment'

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

      attachments_index =
        Submissions.filtered_conditions_schema(submitter.submission).index_by { |i| i['attachment_uuid'] }

      submitter.submission.template_fields.each do |field|
        next if field['submitter_uuid'] != submitter.uuid

        submitter.values.delete(field['uuid']) unless check_field_conditions(submitter, field, fields_uuid_index)

        if field['areas'].present? && field['areas'].none? { |area| attachments_index[area['attachment_uuid']] }
          submitter.values.delete(field['uuid'])
        end
      end

      submitter.values
    end

    def check_field_conditions(submitter, field, fields_uuid_index)
      return true if field['conditions'].blank?

      submitter_values = submitter.values

      field['conditions'].each_with_object([]) do |c, acc|
        if c['operation'] == 'or'
          acc.push(acc.pop || check_field_condition(c, submitter_values, fields_uuid_index))
        else
          acc.push(check_field_condition(c, submitter_values, fields_uuid_index))
        end
      end.exclude?(false)
    end

    def check_field_condition(condition, submitter_values, fields_uuid_index)
      case condition['action']
      when 'empty', 'unchecked'
        submitter_values[condition['field_uuid']].blank?
      when 'not_empty', 'checked'
        submitter_values[condition['field_uuid']].present?
      when 'equal', 'contains'
        field = fields_uuid_index[condition['field_uuid']]
        option = field['options'].find { |o| o['uuid'] == condition['value'] }
        values = Array.wrap(submitter_values[condition['field_uuid']])

        values.include?(option['value'].presence || "#{I18n.t('option')} #{field['options'].index(option)}")
      when 'not_equal', 'does_not_contain'
        field = fields_uuid_index[condition['field_uuid']]
        option = field['options'].find { |o| o['uuid'] == condition['value'] }
        values = Array.wrap(submitter_values[condition['field_uuid']])

        values.exclude?(option['value'].presence || "#{I18n.t('option')} #{field['options'].index(option)}")
      else
        true
      end
    end

    def replace_default_variables(value, attrs, submission, with_time: false)
      return value if value.in?([true, false]) || value.is_a?(Numeric)
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
            Time.current.in_time_zone(submission.account.timezone).to_date.to_s
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
