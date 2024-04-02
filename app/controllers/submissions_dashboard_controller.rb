# frozen_string_literal: true

class SubmissionsDashboardController < ApplicationController
  load_and_authorize_resource :submission, parent: false

  def index
    @submissions = @submissions.joins(:template)

    @submissions = @submissions.where(archived_at: nil)
                               .where(templates: { archived_at: nil })
                               .preload(:created_by_user, template: :author)

    @submissions = Submissions.search(@submissions, params[:q], search_template: true)

    @submissions = @submissions.pending if params[:status] == 'pending'
    @submissions = @submissions.completed if params[:status] == 'completed'

    @pagy, @submissions = pagy(@submissions.preload(:submitters).order(id: :desc))
  end
end
