# frozen_string_literal: true

module Templates
  module Clone
    module_function

    def call(original_template, author:, external_id: nil, name: nil, folder_name: nil)
      template = original_template.account.templates.new

      template.external_id = external_id
      template.author = author
      template.preferences = original_template.preferences.deep_dup
      template.name = name.presence || "#{original_template.name} (#{I18n.t('clone')})"

      if folder_name.present?
        template.folder = TemplateFolders.find_or_create_by_name(author, folder_name)
      else
        template.folder_id = original_template.folder_id
      end

      template.submitters, template.fields, template.schema =
        update_submitters_and_fields_and_schema(original_template.submitters.deep_dup,
                                                original_template.fields.deep_dup,
                                                original_template.schema.deep_dup)

      if name.present? && template.schema.size == 1 &&
         original_template.schema.first['name'] == original_template.name &&
         template.name != "#{original_template.name} (#{I18n.t('clone')})"
        template.schema.first['name'] = template.name
      end

      template
    end

    def update_submitters_and_fields_and_schema(cloned_submitters, cloned_fields, cloned_schema)
      submitter_uuids_replacements = {}
      field_uuids_replacements = {}

      cloned_submitters.each do |submitter|
        new_submitter_uuid = SecureRandom.uuid

        submitter_uuids_replacements[submitter['uuid']] = new_submitter_uuid
        submitter['uuid'] = new_submitter_uuid
      end

      cloned_fields.each do |field|
        new_field_uuid = SecureRandom.uuid

        field_uuids_replacements[field['uuid']] = new_field_uuid
        field['uuid'] = new_field_uuid

        field['submitter_uuid'] = submitter_uuids_replacements[field['submitter_uuid']]
      end

      replace_fields_regexp = nil

      cloned_fields.each do |field|
        Array.wrap(field['conditions']).each do |condition|
          condition['field_uuid'] = field_uuids_replacements[condition['field_uuid']]
        end

        next if field.dig('preferences', 'formula').blank?

        replace_fields_regexp ||= Regexp.union(field_uuids_replacements.keys)

        field['preferences']['formula'] =
          field['preferences']['formula'].gsub(replace_fields_regexp, field_uuids_replacements)
      end

      cloned_schema.each do |field|
        Array.wrap(field['conditions']).each do |condition|
          condition['field_uuid'] = field_uuids_replacements[condition['field_uuid']]
        end
      end

      [cloned_submitters, cloned_fields, cloned_schema]
    end
  end
end
