# frozen_string_literal: true

class TeamsController < ApplicationController
  load_and_authorize_resource :team

  before_action :set_teams, only: :index

  def index; end

  def new; end

  def edit; end

  def create
    @team.account = current_account

    if @team.save
      redirect_back fallback_location: settings_teams_path, notice: I18n.t('team_has_been_created')
    else
      render turbo_stream: turbo_stream.replace(:modal, template: 'teams/new'), status: :unprocessable_content
    end
  end

  def update
    if @team.update(team_params)
      redirect_back fallback_location: settings_teams_path, notice: I18n.t('team_has_been_updated')
    else
      render turbo_stream: turbo_stream.replace(:modal, template: 'teams/edit'), status: :unprocessable_content
    end
  end

  def destroy
    @team.update!(archived_at: Time.current)

    redirect_back fallback_location: settings_teams_path, notice: I18n.t('team_has_been_archived')
  end

  private

  def set_teams
    @teams = current_account.teams.active
                             .left_joins(:users)
                             .where(users: { archived_at: nil })
                             .or(current_account.teams.active.where.missing(:users))
                             .select('teams.*, COUNT(users.id) AS active_users_count')
                             .group('teams.id')
                             .order(:name)
  end

  def team_params
    params.require(:team).permit(:name)
  end
end
