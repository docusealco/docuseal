# frozen_string_literal: true

class TemplatesArchivedSubmissionsController < ApplicationController
  load_and_authorize_resource :template
  load_and_authorize_resource :submission, through: :template, parent: false

  def index
    @submissions = @submissions.where.not(archived_at: nil)
    @submissions = Submissions.search(current_user, @submissions, params[:q], search_values: true)
    @submissions = Submissions::Filter.call(@submissions, current_user, params)

    @submissions = if params[:completed_at_from].present? || params[:completed_at_to].present?
                     @submissions.order(Submitter.arel_table[:completed_at].maximum.desc)
                   else
                     @submissions.order(id: :desc)
                   end

    @pagy, @submissions = pagy_auto(@submissions.preload(submitters: :start_form_submission_events))
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path
  end
end
