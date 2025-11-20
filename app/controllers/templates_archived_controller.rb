# frozen_string_literal: true

class TemplatesArchivedController < ApplicationController
  load_and_authorize_resource :template, parent: false

  def index
    @templates = @templates.where.not(archived_at: nil)
                           .preload(:author, :template_accesses, folder: :parent_folder)
                           .order(id: :desc)

    @templates = Templates.search(current_user, @templates, params[:q])

    @pagy, @templates = pagy_auto(@templates, limit: 12)

    return unless params[:q].present? && @templates.blank?

    @related_submissions =
      Submission.accessible_by(current_ability)
                .joins(:template)
                .where.not(templates: { archived_at: nil })
                .preload(:template_accesses, :created_by_user,
                         template: :author,
                         submitters: :start_form_submission_events)

    @related_submissions = Submissions.search(current_user, @related_submissions, params[:q])
                                      .order(id: :desc)

    @related_submissions_pagy, @related_submissions = pagy_auto(@related_submissions, limit: 5)
  end
end
