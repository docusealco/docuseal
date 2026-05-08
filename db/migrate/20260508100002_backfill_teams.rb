# frozen_string_literal: true

class BackfillTeams < ActiveRecord::Migration[8.0]
  def up
    Account.find_each do |account|
      ActiveRecord::Base.transaction do
        team = Team.create!(
          name: 'Default',
          account: account,
          uuid: SecureRandom.uuid
        )

        User.where(account_id: account.id, team_id: nil).update_all(team_id: team.id)
        Template.where(account_id: account.id, team_id: nil).update_all(team_id: team.id)
        Submission.where(account_id: account.id, team_id: nil).update_all(team_id: team.id)
        Submitter.where(account_id: account.id, team_id: nil).update_all(team_id: team.id)
        TemplateFolder.where(account_id: account.id, team_id: nil).update_all(team_id: team.id)
      end
    end

    change_column_null :users, :team_id, false
  end

  def down
    change_column_null :users, :team_id, true
  end
end
