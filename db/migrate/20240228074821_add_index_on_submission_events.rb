# frozen_string_literal: true

class AddIndexOnSubmissionEvents < ActiveRecord::Migration[7.1]
  def change
    add_index :submission_events, :created_at
  end
end
