# frozen_string_literal: true

module Templates
  module Clone
    module_function

    # rubocop:disable Metrics, Style/CombinableLoops
    def call(original_template, author:, external_id: nil, name: nil, folder_name: nil,
             target_account: nil, target_partnership: nil)
      # Determine the target for the cloned template
      template = Template.new

      if target_account.present?
        template.assign_attributes(account: target_account, partnership: nil)
      elsif target_partnership.present?
        template.assign_attributes(partnership: target_partnership, account: nil)
      else
        raise ArgumentError, 'Either target_account or target_partnership must be provided'
      end

      template.external_id = external_id
      template.shared_link = original_template.shared_link
      template.author = author
      template.name = name.presence || "#{original_template.name} (#{I18n.t('clone')})"

      template.folder = determine_template_folder(
        original_template,
        target_account,
        target_partnership,
        author,
        folder_name
      )

      template.submitters, template.fields, template.schema, template.preferences =
        update_submitters_and_fields_and_schema(original_template.submitters.deep_dup,
                                                original_template.fields.deep_dup,
                                                original_template.schema.deep_dup,
                                                original_template.preferences.deep_dup)

      if name.present? && template.schema.size == 1 &&
         original_template.schema.first['name'] == original_template.name &&
         template.name != "#{original_template.name} (#{I18n.t('clone')})"
        template.schema.first['name'] = template.name
      end

      original_template.template_accesses.each do |template_access|
        template.template_accesses.new(user_id: template_access.user_id)
      end

      template
    end

    def update_submitters_and_fields_and_schema(cloned_submitters, cloned_fields, cloned_schema, cloned_preferences)
      submitter_uuids_replacements = {}
      field_uuids_replacements = {}

      cloned_submitters.each do |submitter|
        new_submitter_uuid = SecureRandom.uuid

        submitter_uuids_replacements[submitter['uuid']] = new_submitter_uuid
        submitter['uuid'] = new_submitter_uuid
      end

      cloned_submitters.each do |submitter|
        if submitter['optional_invite_by_uuid'].present?
          submitter['optional_invite_by_uuid'] = submitter_uuids_replacements[submitter['optional_invite_by_uuid']]
        end

        if submitter['invite_by_uuid'].present?
          submitter['invite_by_uuid'] = submitter_uuids_replacements[submitter['invite_by_uuid']]
        end

        if submitter['linked_to_uuid'].present?
          submitter['linked_to_uuid'] = submitter_uuids_replacements[submitter['linked_to_uuid']]
        end
      end

      cloned_preferences['submitters'].to_a.each do |submitter|
        submitter['uuid'] = submitter_uuids_replacements[submitter['uuid']]
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

      [cloned_submitters, cloned_fields, cloned_schema, cloned_preferences]
    end

    def determine_template_folder(original_template, target_account, target_partnership, author, folder_name)
      if folder_name.present?
        create_named_folder(author, folder_name, target_partnership)
      elsif cloning_between_account_and_partnership?(original_template, target_account, target_partnership)
        create_default_folder_for_target(target_account, target_partnership, author)
      else
        return nil if original_template.folder_id.blank?

        original_template.folder || original_template.folder_id
      end
    end

    def create_named_folder(author, folder_name, target_partnership)
      if target_partnership.present?
        TemplateFolders.find_or_create_by_name(author, folder_name, partnership: target_partnership)
      else
        TemplateFolders.find_or_create_by_name(author, folder_name)
      end
    end

    def cloning_between_account_and_partnership?(original_template, target_account, target_partnership)
      # When cloning across entity types (partnership → account or account → partnership),
      # we need to create default folders since folder structures don't transfer
      (target_account.present? && original_template.partnership.present?) ||
        (target_partnership.present? && original_template.account.present?)
    end

    def create_default_folder_for_target(target_account, target_partnership, author)
      if target_partnership.present?
        target_partnership.default_template_folder(author)
      else
        target_account.default_template_folder
      end
    end
    # rubocop:enable Metrics, Style/CombinableLoops
  end
end
