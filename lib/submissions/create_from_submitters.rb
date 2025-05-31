# frozen_string_literal: true

module Submissions
  module CreateFromSubmitters
    BaseError = Class.new(StandardError)

    module_function

    # rubocop:disable Metrics
    def call(template:, user:, submissions_attrs:, source:, submitters_order:, params: {}, with_template: true)
      preferences = Submitters.normalize_preferences(user.account, user, params)

      submissions = Array.wrap(submissions_attrs).filter_map do |attrs|
        submission_preferences = Submitters.normalize_preferences(user.account, user, attrs)
        submission_preferences = preferences.merge(submission_preferences)

        set_submission_preferences = submission_preferences.slice('send_email', 'bcc_completed')
        set_submission_preferences['send_email'] = true if params['send_completed_email']
        expire_at = attrs[:expire_at] || Templates.build_default_expire_at(template)

        submission = template.submissions.new(created_by_user: user, source:,
                                              account_id: user.account_id,
                                              preferences: set_submission_preferences,
                                              name: with_template ? attrs[:name] : (attrs[:name] || template.name),
                                              expire_at:,
                                              template_submitters: [], submitters_order:)

        template_submitters = template.submitters.deep_dup

        attrs[:submitters].each_with_index do |submitter_attrs, index|
          if submitter_attrs[:roles].present? && submitter_attrs[:roles].size > 1
            template_submitter, template_submitters, submission.template_fields =
              merge_submitters_and_fields(submitter_attrs, template_submitters,
                                          submission.template_fields || submission.template.fields)

            submission.template_schema = submission.template.schema if submission.template_schema.blank?

            uuid = template_submitter['uuid']
          else
            if submitter_attrs[:roles].present? && submitter_attrs[:roles].size == 1
              submitter_attrs[:role] = submitter_attrs[:roles].first
            end

            uuid = find_submitter_uuid(template_submitters, submitter_attrs, index)

            next if uuid.blank?
            next if submitter_attrs.slice('email', 'phone', 'name').compact_blank.blank?

            submission.template_fields = submission.template.fields if submitter_attrs[:completed].present? &&
                                                                       submission.template_fields.blank?

            template_submitter = template_submitters.find { |e| e['uuid'] == uuid }
          end

          submission.template_submitters << template_submitter.except('optional_invite_by_uuid', 'invite_by_uuid')

          is_order_sent = submitters_order == 'random' || index.zero?

          build_submitter(submission:, attrs: submitter_attrs,
                          uuid:, is_order_sent:, user:, params:,
                          preferences: preferences.merge(submission_preferences))
        end

        maybe_set_template_fields(submission, attrs[:submitters], with_template:)

        if submission.submitters.size > template.submitters.size
          raise BaseError, 'Defined more signing parties than in template'
        end

        if template.preferences['validate_unique_submitters'] == true
          submission_emails = submission.submitters.filter_map(&:email)

          raise BaseError, 'Recipient emails should differ' if submission_emails.uniq.size != submission_emails.size
        end

        next if submission.submitters.blank?

        maybe_add_invite_submitters(submission, template)

        submission.template = nil unless with_template

        submission.tap(&:save!)
      end

      maybe_enqueue_expire_at(submissions)

      submissions
    end
    # rubocop:enable Metrics

    def maybe_enqueue_expire_at(submissions)
      submissions.each do |submission|
        next unless submission.expire_at?

        ProcessSubmissionExpiredJob.perform_at(submission.expire_at, 'submission_id' => submission.id)
      end
    end

    def maybe_add_invite_submitters(submission, template)
      template.submitters.each_with_index do |item, index|
        next if item['invite_by_uuid'].blank? && item['optional_invite_by_uuid'].blank?
        next if submission.template_submitters.any? { |e| e['uuid'] == item['uuid'] }

        if index.zero?
          submission.template_submitters.insert(1, item)
        elsif submission.template_submitters.size > index
          submission.template_submitters.insert(index, item)
        else
          submission.template_submitters << item
        end
      end
    end

    def submitter_message_preferences(uuid, params)
      return {} if params[:request_email_per_submitter] != '1'
      return {} if params[:is_custom_message] != '1'

      {
        'subject' => params.dig('submitter_preferences', uuid, 'subject'),
        'body' => params.dig('submitter_preferences', uuid, 'body')
      }.compact_blank
    end

    def maybe_set_template_fields(submission, submitters_attrs, default_submitter_uuid: nil, with_template: true)
      template_fields = (submission.template_fields || submission.template.fields).deep_dup

      submitters = submission.template_submitters || submission.template.submitters

      submitters_attrs.each_with_index do |submitter_attrs, index|
        submitter_uuid = default_submitter_uuid || find_submitter_uuid(submitters, submitter_attrs, index)

        process_readonly_fields_param(submitter_attrs[:readonly_fields], template_fields, submitter_uuid)
        process_field_values_param(submitter_attrs[:values], template_fields, submitter_uuid)

        process_fields_param(submitter_attrs[:fields], template_fields, submitter_uuid)
      end

      if template_fields != (submission.template_fields || submission.template.fields) ||
         submitters_attrs.any? { |e| e[:completed].present? } || !with_template
        submission.template_fields = template_fields
        submission.template_schema = submission.template.schema if submission.template_schema.blank?
      end

      submission
    end

    def merge_submitters_and_fields(submitter_attrs, template_submitters, template_fields)
      selected_submitters = submitter_attrs[:roles].map do |role|
        template_submitters.find { |e| e['name'].to_s.casecmp(role).zero? } ||
          raise(BaseError, "#{role} role doesn't exist")
      end

      merge_role_uuids = selected_submitters.pluck('uuid')
      old_role_uuids = template_submitters.pluck('uuid')
      name = submitter_attrs[:role].presence || selected_submitters.pluck('name').join(' / ')

      merged_submitter, template_submitters =
        build_merged_submitter(template_submitters, role_uuids: merge_role_uuids, name:)

      field_names_index = {}

      sorted_fields = template_fields.sort_by { |e| old_role_uuids.index(e['submitter_uuid']) }

      sorted_fields.each do |field|
        next unless merge_role_uuids.include?(field['submitter_uuid'])

        if (existing_field = field_names_index[field['name']])
          existing_field['areas'] ||= []
          existing_field['areas'].push(*field['areas'])
          template_fields.delete(field)
        else
          field['submitter_uuid'] = merged_submitter['uuid']
          field_names_index[field['name']] = field if field['name'].present?
        end
      end

      [merged_submitter, template_submitters, template_fields]
    end

    def build_merged_submitter(submitters, role_uuids:, name:)
      new_uuid = Digest::UUID.uuid_v5(Digest::UUID::OID_NAMESPACE, role_uuids.sort.join(':'))

      merged_submitter = nil

      submitters =
        submitters.filter_map do |submitter|
          submitter['optional_invite_by_uuid'] = new_uuid if role_uuids.include?(submitter['optional_invite_by_uuid'])
          submitter['invite_by_uuid'] = new_uuid if role_uuids.include?(submitter['invite_by_uuid'])
          submitter['linked_to_uuid'] = new_uuid if role_uuids.include?(submitter['linked_to_uuid'])

          if role_uuids.include?(submitter['uuid'])
            next if merged_submitter

            merged_submitter = submitter.deep_dup
            merged_submitter['uuid'] = new_uuid
            merged_submitter['name'] = name
            merged_submitter.delete('linked_to_uuid')
          end

          submitter
        end

      [merged_submitter, submitters]
    end

    def process_readonly_fields_param(readonly_fields, template_fields, submitter_uuid)
      return if readonly_fields.blank?

      template_fields.each do |f|
        next if f['submitter_uuid'] != submitter_uuid ||
                (!f['name'].in?(readonly_fields) &&
                 !f['name'].to_s.downcase.in?(readonly_fields) &&
                 !f['name'].to_s.parameterize.underscore.in?(readonly_fields))

        f['readonly'] = true
      end
    end

    def process_field_values_param(values, template_fields, submitter_uuid)
      return if values.blank?

      template_fields.each do |f|
        next if f['type'].in?(%w[signature image initials file])
        next if f['submitter_uuid'] != submitter_uuid

        next unless values.key?(f['uuid'])

        value = values[f['uuid']]

        if value.present?
          f['default_value'] = value
        else
          f.delete('default_value')
        end
      end
    end

    def process_fields_param(fields, template_fields, submitter_uuid)
      return if fields.blank?

      template_fields.each do |f|
        next if f['submitter_uuid'] != submitter_uuid

        field_configs = fields.find do |e|
          if e['name'].present?
            e['name'].to_s.casecmp(f['name'].to_s).zero? || e['name'] == f['name'].to_s.parameterize.underscore
          else
            e['uuid'] == f['uuid']
          end
        end

        next if field_configs.blank?

        assign_field_attrs(f, field_configs)
      end
    end

    def assign_field_attrs(field, attrs)
      field['title'] = attrs['title'] if attrs['title'].present?
      field['description'] = attrs['description'] if attrs['description'].present?
      field['readonly'] = attrs['readonly'] if attrs.key?('readonly')
      field['required'] = attrs['required'] if attrs.key?('required')

      if attrs.key?('default_value') && !field['type'].in?(%w[signature image initials file])
        if attrs['default_value'].present?
          field['default_value'] = Submitters::NormalizeValues.normalize_value(field, attrs['default_value'])
        else
          field.delete('default_value')
        end
      end

      field['preferences'] = (field['preferences'] || {}).merge(attrs['preferences']) if attrs['preferences'].present?

      return field if attrs['validation_pattern'].blank?

      field['validation'] = {
        'pattern' => attrs['validation_pattern'],
        'message' => attrs['invalid_message']
      }.compact_blank

      field
    end

    def find_submitter_uuid(submitters, attrs, index)
      uuid = attrs[:uuid].presence
      uuid ||= submitters.find { |e| e['name'].to_s.casecmp(attrs[:role].to_s).zero? }&.dig('uuid')

      uuid || submitters[index]&.dig('uuid')
    end

    def build_submitter(submission:, attrs:, uuid:, is_order_sent:, user:, preferences:, params:)
      email = Submissions.normalize_email(attrs[:email])
      submitter_preferences = Submitters.normalize_preferences(submission.account, user,
                                                               attrs.merge(submitter_message_preferences(uuid, params)))
      values = attrs[:values] || {}

      phone_field_uuid = find_phone_field(submission, values)&.dig('uuid')

      submitter =
        submission.submitters.new(
          email:,
          phone: (attrs[:phone] || values[phone_field_uuid]).to_s.gsub(/[^0-9+]/, ''),
          name: attrs[:name],
          account_id: user.account_id,
          external_id: attrs[:external_id].presence || attrs[:application_key],
          completed_at: attrs[:completed].present? ? Time.current : nil,
          values: values.except(phone_field_uuid),
          metadata: attrs[:metadata] || {},
          preferences: preferences.merge(submitter_preferences)
                                  .merge({ default_values: attrs[:values] }.compact_blank)
                                  .except('bcc_completed'),
          uuid:
        )

      submitter.sent_at =
        submitter.preferences['send_email'] != false && email.present? && is_order_sent ? Time.current : nil

      assign_completed_attributes(submitter) if submitter.completed_at?

      submitter
    end

    def find_phone_field(submission, values)
      (submission.template_fields || submission.template.fields).find do |f|
        values[f['uuid']].present? && f['type'] == 'phone'
      end
    end

    def assign_completed_attributes(submitter)
      submitter.values = Submitters::SubmitValues.merge_default_values(submitter)
      submitter.values = Submitters::SubmitValues.maybe_remove_condition_values(submitter)

      formula_values = Submitters::SubmitValues.build_formula_values(submitter)

      if formula_values.present?
        submitter.values = submitter.values.merge(formula_values)
        submitter.values = Submitters::SubmitValues.maybe_remove_condition_values(submitter)
      end

      submitter.values = submitter.values.transform_values do |v|
        v == '{{date}}' ? Time.current.in_time_zone(submitter.submission.account.timezone).to_date.to_s : v
      end

      submitter
    end
  end
end
