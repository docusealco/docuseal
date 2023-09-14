# frozen_string_literal: true

class TemplatesArchivedSubmissionsController < ApplicationController
  def show
    @template = current_account.templates.find(params[:template_id])

    @pagy, @submissions = pagy(@template.submissions.where.not(deleted_at: nil).preload(:submitters).order(id: :desc))
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path
  end
end
