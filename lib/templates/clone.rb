# frozen_string_literal: true

module Templates
  module Clone
    module_function

    def call(original_template, author:, external_id: nil, name: nil, folder_name: nil)
      template = original_template.account.templates.new

      template.external_id = external_id
      template.author = author
      template.preferences = original_template.preferences.deep_dup
      template.name = name || "#{original_template.name} (Clone)"

      template.assign_attributes(original_template.slice(:folder_id, :schema))

      template.folder = TemplateFolders.find_or_create_by_name(author, folder_name) if folder_name.present?

      template.submitters, template.fields = clone_submitters_and_fields(original_template)

      template
    end

    def clone_submitters_and_fields(original_template)
      submitter_uuids_replacements = {}
      field_uuids_replacements = {}

      cloned_submitters = original_template['submitters'].deep_dup
      cloned_fields = original_template['fields'].deep_dup

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

      replace_fields_regexp = Regexp.union(field_uuids_replacements.keys)

      cloned_fields.each do |field|
        Array.wrap(field['conditions']).each do |condition|
          condition['field_uuid'] = field_uuids_replacements[condition['field_uuid']]
        end

        if field.dig('preferences', 'formula').present?
          field['preferences']['formula'] =
            field['preferences']['formula'].gsub(replace_fields_regexp, field_uuids_replacements)
        end
      end

      [cloned_submitters, cloned_fields]
    end
  end
end
