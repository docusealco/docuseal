# frozen_string_literal: true

class SubmissionsDashboardController < ApplicationController
  load_and_authorize_resource :submission, parent: false

  def index
    @submissions = @submissions.left_joins(:template)

    @submissions = @submissions.where(archived_at: nil)
                               .where(templates: { archived_at: nil })
                               .preload(:template_accesses, :created_by_user)

    @submissions = Submissions.search(current_user, @submissions, params[:q], search_template: true)
    @submissions = Submissions::Filter.call(@submissions, current_user, params)

    @submissions = if params[:completed_at_from].present? || params[:completed_at_to].present?
                     @submissions.order(Submitter.arel_table[:completed_at].maximum.desc)
                   else
                     @submissions.order(id: :desc)
                   end

    @pagy, @submissions = pagy_auto(@submissions.select_for_list.preload(submitters: :start_form_submission_events))

    template_scope = @submissions.all?(&:template_submitters) ? Template.select_for_list : nil

    ActiveRecord::Associations::Preloader.new(records: @submissions,
                                              associations: :template,
                                              scope: template_scope).call

    ActiveRecord::Associations::Preloader.new(records: @submissions.filter_map(&:template),
                                              associations: :author).call
  end
end
