# frozen_string_literal: true

class AddTeamIdToResources < ActiveRecord::Migration[8.0]
  def change
    add_reference :users, :team, foreign_key: true
    add_reference :templates, :team, foreign_key: true
    add_reference :submissions, :team, foreign_key: true
    add_reference :submitters, :team, foreign_key: true
    add_reference :template_folders, :team, foreign_key: true
  end
end
