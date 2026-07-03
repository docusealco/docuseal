# frozen_string_literal: true

class TemplatesSharedController < ApplicationController
  def index
    authorize!(:read, Template)

    @is_archived = params[:archived] == 'true'

    @templates = Templates.shared(current_user)

    @has_archived = !@is_archived && @templates.archived.exists?

    @templates = @is_archived ? @templates.archived : @templates.active

    @templates = @templates.preload(:author, :template_accesses, :template_sharings)
                           .order(id: :desc)

    @templates = Templates.search_shared(current_user, @templates, params[:q])

    @pagy, @templates = pagy_auto(@templates.select_for_list, limit: 12)

    return unless params[:q].present? && @templates.blank?

    @related_submissions_pagy, @related_submissions = load_related_submissions(is_archived: @is_archived)
  end

  private

  def load_related_submissions(is_archived:)
    shared_templates = Templates.shared(current_user)
    shared_templates = is_archived ? shared_templates.archived : shared_templates.active

    related_submissions =
      Submission.accessible_by(current_ability)
                .where(template_id: shared_templates.select(:id))
                .preload(:template_accesses, :created_by_user,
                         template: :author,
                         submitters: :start_form_submission_events)

    related_submissions = related_submissions.where(archived_at: nil) unless is_archived

    related_submissions = Submissions.search(current_user, related_submissions, params[:q])
                                     .order(id: :desc)

    pagy_auto(related_submissions.select_for_list, limit: 5)
  end
end
