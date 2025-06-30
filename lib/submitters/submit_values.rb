# frozen_string_literal: true

module Submitters
  module SubmitValues
    ValidationError = Class.new(StandardError)
    RequiredFieldError = Class.new(StandardError)

    VARIABLE_REGEXP = /\{\{?(\w+)\}\}?/
    NONEDITABLE_FIELD_TYPES = %w[stamp heading].freeze

    module_function

    def call(submitter, params, request, validate_required: true)
      Submissions.update_template_fields!(submitter.submission) if submitter.submission.template_fields.blank?

      unless submitter.submission_events.exists?(event_type: 'start_form')
        SubmissionEvents.create_with_tracking_data(submitter, 'start_form', request)

        WebhookUrls.for_account_id(submitter.account_id, 'form.started').each do |webhook_url|
          SendFormStartedWebhookRequestJob.perform_async('submitter_id' => submitter.id,
                                                         'webhook_url_id' => webhook_url.id)
        end
      end

      update_submitter!(submitter, params, request, validate_required:)

      submitter.submission.save!

      ProcessSubmitterCompletionJob.perform_async('submitter_id' => submitter.id) if submitter.completed_at?

      submitter
    end

    def update_submitter!(submitter, params, request, validate_required: true)
      values = normalized_values(params)

      submitter.values.merge!(values)
      submitter.opened_at ||= Time.current

      assign_completed_attributes(submitter, request, validate_required:) if params[:completed] == 'true'

      ApplicationRecord.transaction do
        maybe_set_signature_reason!(values, submitter, params)
        validate_values!(values, submitter, params, request)

        SubmissionEvents.create_with_tracking_data(submitter, 'complete_form', request) if params[:completed] == 'true'

        submitter.save!
      end

      SearchEntries.enqueue_reindex(submitter) if submitter.completed_at?

      submitter
    end

    def assign_completed_attributes(submitter, request, validate_required: true)
      submitter.completed_at = Time.current
      submitter.ip = request.remote_ip
      submitter.ua = request.user_agent
      submitter.timezone = request.params[:timezone]

      submitter.values = merge_default_values(submitter)

      required_field_uuids_acc = Set.new

      submitter.values = maybe_remove_condition_values(submitter, required_field_uuids_acc:)

      formula_values = build_formula_values(submitter)

      if formula_values.present?
        submitter.values = submitter.values.merge(formula_values)
        submitter.values = maybe_remove_condition_values(submitter, required_field_uuids_acc:)
      end

      submitter.values = submitter.values.transform_values do |v|
        v == '{{date}}' ? Time.current.in_time_zone(submitter.account.timezone).to_date.to_s : v
      end

      required_field_uuids_acc.each do |uuid|
        next if submitter.values[uuid].present?

        raise RequiredFieldError, uuid if validate_required

        Rollbar.warning("Required field #{submitter.id}: #{uuid}") if defined?(Rollbar)
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

    def build_formula_values(submitter)
      submission_values = nil

      computed_values = submitter.submission.template_fields.each_with_object({}) do |field, acc|
        next if field['submitter_uuid'] != submitter.uuid
        next if field['type'] == 'payment'

        formula = field.dig('preferences', 'formula')

        next if formula.blank?

        submission_values ||=
          if submitter.submission.template_submitters.size > 1
            merge_submitters_values(submitter)
          else
            submitter.values
          end

        acc[field['uuid']] = calculate_formula_value(formula, submission_values.merge(acc.compact_blank))
      end

      computed_values.compact_blank
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

    def maybe_remove_condition_values(submitter, required_field_uuids_acc: nil)
      submission = submitter.submission

      submitters_values = nil
      has_other_submitters = submission.template_submitters.size > 1

      has_document_conditions = submission_has_document_conditions?(submission)

      attachments_index =
        if has_document_conditions
          Submissions.filtered_conditions_schema(submission).index_by { |i| i['attachment_uuid'] }
        end

      submission.template_fields.each do |field|
        next if field['submitter_uuid'] != submitter.uuid

        required_field_uuids_acc.add(field['uuid']) if required_field_uuids_acc && required_editable_field?(field)

        if has_document_conditions && !check_field_areas_attachments(field, attachments_index)
          submitter.values.delete(field['uuid'])
          required_field_uuids_acc&.delete(field['uuid'])
        end

        if has_other_submitters && !submitters_values &&
           field_conditions_other_submitter?(submitter, field, submission.fields_uuid_index)
          submitters_values = merge_submitters_values(submitter)
        end

        unless check_field_conditions(submitters_values || submitter.values, field, submission.fields_uuid_index)
          submitter.values.delete(field['uuid'])
          required_field_uuids_acc&.delete(field['uuid'])
        end
      end

      submitter.values
    end

    def submission_has_document_conditions?(submission)
      (submission.template_schema || submission.template.schema).any? { |e| e['conditions'].present? }
    end

    def required_editable_field?(field)
      return false if NONEDITABLE_FIELD_TYPES.include?(field['type'])

      field['required'].present? && field['readonly'].blank?
    end

    def check_field_areas_attachments(field, attachments_index)
      return true if field['areas'].blank?

      field['areas'].any? { |area| attachments_index[area['attachment_uuid']] }
    end

    def merge_submitters_values(submitter)
      submitter.submission.submitters
               .reduce({}) { |acc, sub| acc.merge(sub.values) }
               .merge(submitter.values)
    end

    def field_conditions_other_submitter?(submitter, field, fields_uuid_index)
      return false if field['conditions'].blank?

      field['conditions'].to_a.any? do |c|
        fields_uuid_index.dig(c['field_uuid'], 'submitter_uuid') != submitter.uuid
      end
    end

    def check_field_conditions(submitter_values, field, fields_uuid_index)
      return true if field['conditions'].blank?

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

        values.include?(option['value'].presence || "#{I18n.t('option')} #{field['options'].index(option) + 1}")
      when 'not_equal', 'does_not_contain'
        field = fields_uuid_index[condition['field_uuid']]
        option = field['options'].find { |o| o['uuid'] == condition['value'] }
        values = Array.wrap(submitter_values[condition['field_uuid']])

        values.exclude?(option['value'].presence || "#{I18n.t('option')} #{field['options'].index(option) + 1}")
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
