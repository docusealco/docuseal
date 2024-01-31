# frozen_string_literal: true

module Templates
  module Clone
    module_function

    def call(original_template, author:, external_id: nil, name: nil, folder_name: nil)
      original_template_account = original_template.account

      template = original_template_account.templates.new

      template.external_id = external_id
      template.author = author
      template.name = name || "#{original_template.name} (Clone)"

      template.assign_attributes(original_template.slice(:folder_id, :schema))

      template.folder = TemplateFolders.find_or_create_by_name(author, folder_name) if folder_name.present?

      submitter_uuids_replacements = {}

      cloned_submitters = original_template['submitters'].deep_dup
      cloned_fields = original_template['fields'].deep_dup

      cloned_submitters.each do |submitter|
        new_submitter_uuid = SecureRandom.uuid

        submitter_uuids_replacements[submitter['uuid']] = new_submitter_uuid
        submitter['uuid'] = new_submitter_uuid
      end

      cloned_fields.each do |field|
        field['uuid'] = SecureRandom.uuid
        field['submitter_uuid'] = submitter_uuids_replacements[field['submitter_uuid']]
      end

      template.assign_attributes(fields: cloned_fields, submitters: cloned_submitters)

      template
    end
  end
end
