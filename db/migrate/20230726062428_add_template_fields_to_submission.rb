# frozen_string_literal: true

class AddTemplateFieldsToSubmission < ActiveRecord::Migration[7.0]
  class MigrationTemplate < ApplicationRecord
    self.table_name = 'templates'
  end

  class MigrationSubmission < ApplicationRecord
    self.table_name = 'submissions'
  end

  def up
    add_column :submissions, :template_fields, :text
    add_column :submissions, :template_schema, :text
    add_column :submissions, :template_submitters, :text

    MigrationTemplate.all.each do |template|
      MigrationSubmission.where(template_id: template.id).each do |submission|
        submission.update_columns(template_fields: template.fields,
                                  template_schema: template.schema,
                                  template_submitters: template.submitters)
      end
    end
  end

  def down
    remove_column :submissions, :template_fields
    remove_column :submissions, :template_schema
    remove_column :submissions, :template_submitters
  end
end
