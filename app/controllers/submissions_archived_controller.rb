# frozen_string_literal: true

class SubmissionsArchivedController < ApplicationController
  load_and_authorize_resource :submission, parent: false

  def index
    @submissions = @submissions.joins(:template)
    @submissions = @submissions.where.not(archived_at: nil)
                               .or(@submissions.where.not(templates: { archived_at: nil }))
                               .preload(:created_by_user, template: :author)
    @submissions = Submissions.search(@submissions, params[:q], search_template: true)

    @pagy, @submissions = pagy(@submissions.preload(:submitters).order(id: :desc))
  end
end
