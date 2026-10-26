# frozen_string_literal: true

class AddSubmissionCreatedAtIndex < ActiveRecord::Migration[8.1]
  def change
    add_index :submissions, :created_at, if_not_exists: true
  end
end
