# frozen_string_literal: true

module Submitters
  module MaybeUpdateDefaultValues
    module_function

    def call(submitter, current_user)
      user =
        if current_user && current_user.email == submitter.email
          current_user
        else
          submitter.account.users.find_by(email: submitter.email)
        end

      return if user.blank?

      fields = submitter.submission.template_fields || submitter.submission.template.fields

      fields.each do |field|
        next if field['submitter_uuid'] != submitter.uuid

        default_value = get_default_value_for_field(field, user, submitter)

        submitter.values[field['uuid']] ||= default_value if default_value.present?
      end

      submitter.save!
    end

    def get_default_value_for_field(field, user, submitter)
      field_name = field['name'].to_s.downcase

      if field_name.in?(['full name', 'legal name'])
        user.full_name
      elsif field_name == 'first name'
        user.first_name
      elsif field_name == 'last name'
        user.last_name
      elsif field['type'] == 'initials' && (initials = UserConfigs.load_initials(user))
        attachment = ActiveStorage::Attachment.find_or_create_by!(
          blob_id: initials.blob_id,
          name: 'attachments',
          record: submitter
        )

        attachment.uuid
      end
    end
  end
end
