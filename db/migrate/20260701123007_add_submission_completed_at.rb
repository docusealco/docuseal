# frozen_string_literal: true

class AddSubmissionCompletedAt < ActiveRecord::Migration[8.1]
  def change
    add_column :submissions, :completed_at, :datetime
  end
end
