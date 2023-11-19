# frozen_string_literal: true

class AddSlugToSubmissions < ActiveRecord::Migration[7.0]
  class MigrationSubmission < ApplicationRecord
    self.table_name = 'submissions'
  end

  def up
    add_column :submissions, :slug, :string

    MigrationSubmission.where(slug: nil).find_each do |submission|
      submission.update_columns(slug: SecureRandom.base58(14))
    end

    change_column_null :submissions, :slug, false

    add_index :submissions, :slug, unique: true
  end

  def down
    remove_column :submissions, :slug
  end
end
