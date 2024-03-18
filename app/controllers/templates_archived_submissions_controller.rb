# frozen_string_literal: true

class TemplatesArchivedSubmissionsController < ApplicationController
  load_and_authorize_resource :template
  load_and_authorize_resource :submission, through: :template, parent: false

  def index
    @submissions = @submissions.where.not(archived_at: nil)
    @submissions = Submissions.search(@submissions, params[:q], search_values: true)

    @pagy, @submissions = pagy(@submissions.preload(:submitters).order(id: :desc))
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path
  end
end
