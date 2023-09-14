# frozen_string_literal: true

class TemplatesArchivedSubmissionsController < ApplicationController
  def show
    @template = current_account.templates.find(params[:template_id])

    submissions = @template.submissions.where.not(deleted_at: nil)
    submissions = Submissions.search(submissions, params[:q])

    @pagy, @submissions = pagy(submissions.preload(:submitters).order(id: :desc))
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path
  end
end
