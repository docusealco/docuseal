# frozen_string_literal: true

class AddVerificationMethodToCompletedSubmitters < ActiveRecord::Migration[8.0]
  def change
    add_column :completed_submitters, :verification_method, :string
  end
end
