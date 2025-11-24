# frozen_string_literal: true

class AddAccountIdToSubmissionEvents < ActiveRecord::Migration[8.0]
  def change
    add_reference :submission_events, :account, null: true, foreign_key: true, index: true
  end
end
