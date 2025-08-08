# frozen_string_literal: true

class AddTemplateFieldsToSubmission < ActiveRecord::Migration[7.0]
  class MigrationTemplate < ApplicationRecord
    self.table_name = 'templates'
  end

  class MigrationSubmission < ApplicationRecord
    self.table_name = 'submissions'
  end

  def up
    change_table :submissions, bulk: true do |t|
      t.text :template_fields
      t.text :template_schema
      t.text :template_submitters
    end

    MigrationTemplate.all.each do |template|
      MigrationSubmission.where(template_id: template.id).each do |submission|
        submission.update_columns(template_fields: template.fields,
                                  template_schema: template.schema,
                                  template_submitters: template.submitters)
      end
    end
  end

  def down
    change_table :submissions, bulk: true do |t|
      t.remove :template_fields
      t.remove :template_schema
      t.remove :template_submitters
    end
  end
end
