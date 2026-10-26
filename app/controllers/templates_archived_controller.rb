# frozen_string_literal: true

class TemplatesArchivedController < ApplicationController
  load_and_authorize_resource :template, parent: false

  def index
    @templates = @templates.where.not(archived_at: nil)
                           .preload(:author, :template_accesses, folder: :parent_folder)
                           .order(id: :desc)

    @templates = Templates.search(current_user, @templates, params[:q])

    @pagy, @templates = pagy_auto(@templates.select_for_list, limit: 12)

    if params[:q].present? && @templates.blank?
      @related_submissions_pagy, @related_submissions = load_related_submissions
    end

    render_infinite_scroll(@pagy, @templates) if turbo_infinite_scroll?
  end

  private

  def render_infinite_scroll(pagy, templates)
    render turbo_stream: [
      turbo_stream.before('infinite_scroll', partial: 'templates/template', collection: templates,
                                             locals: { with_folder: true }),
      turbo_stream.replace('infinite_scroll', partial: 'shared/infinite_scroll', locals: { pagy: })
    ]
  end

  def load_related_submissions
    related_submissions =
      Submission.accessible_by(current_ability)
                .joins(:template)
                .where.not(templates: { archived_at: nil })
                .preload(:template_accesses, :created_by_user,
                         template: :author,
                         submitters: :start_form_submission_events)

    related_submissions = Submissions.search(current_user, related_submissions, params[:q])
                                     .order(id: :desc)

    pagy_auto(related_submissions.select_for_list, limit: 5)
  end
end
