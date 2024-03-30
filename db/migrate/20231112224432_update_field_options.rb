# frozen_string_literal: true

class UpdateFieldOptions < ActiveRecord::Migration[7.0]
  class MigrationTemplate < ApplicationRecord
    self.table_name = 'templates'
  end

  class MigrationSubmission < ApplicationRecord
    self.table_name = 'submissions'
  end

  def up
    MigrationTemplate.find_each do |template|
      next if template.fields.blank?

      template_fields = JSON.parse(template.fields)

      new_fields = template_fields.deep_dup

      new_fields.each do |field|
        if field['options'].present? && !field['options'].first.is_a?(Hash)
          field['options'] = field['options'].map { |o| { value: o || '', uuid: SecureRandom.uuid } }
        end
      end

      template.update_columns(fields: new_fields.to_json) if template_fields != new_fields
    end

    MigrationSubmission.find_each do |submission|
      next if submission.template_fields.blank?

      template_fields = JSON.parse(submission.template_fields)

      new_fields = template_fields.deep_dup

      new_fields.each do |field|
        if field['options'].present? && !field['options'].first.is_a?(Hash)
          field['options'] = field['options'].map { |o| { value: o || '', uuid: SecureRandom.uuid } }
        end
      end

      submission.update_columns(template_fields: new_fields.to_json) if template_fields != new_fields
    end
  end

  def down
    nil
  end
end
