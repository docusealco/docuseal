# frozen_string_literal: true

class TemplatesDashboardController < ApplicationController
  load_and_authorize_resource :template_folder, parent: false
  load_and_authorize_resource :template, parent: false

  SHOW_TEMPLATES_FOLDERS_THRESHOLD = 9
  TEMPLATES_PER_PAGE = 12
  FOLDERS_PER_PAGE = 18

  helper_method :selected_order

  def index
    @template_folders =
      TemplateFolders.filter_active_folders(@template_folders.where(parent_folder_id: nil), @templates)

    @template_folders = TemplateFolders.search(@template_folders, params[:q])
    @template_folders = TemplateFolders.sort(@template_folders, current_user, selected_order)

    @pagy, @template_folders = pagy(
      @template_folders,
      limit: FOLDERS_PER_PAGE,
      page: @template_folders.count > SHOW_TEMPLATES_FOLDERS_THRESHOLD ? params[:page] : 1
    )

    if @pagy.count > SHOW_TEMPLATES_FOLDERS_THRESHOLD
      @templates = @templates.none
    else
      @template_folders = @template_folders.reject { |e| e.name == TemplateFolder::DEFAULT_NAME }
      @templates = filter_templates(@templates).preload(:author, :template_accesses)
      @templates = Templates::Order.call(@templates, current_user, selected_order)

      limit =
        if @template_folders.size < 4
          TEMPLATES_PER_PAGE
        else
          (@template_folders.size < 7 ? 9 : 6)
        end

      @pagy, @templates = pagy_auto(@templates, limit:)

      load_related_submissions if params[:q].present? && @templates.blank?
    end
  end

  private

  def filter_templates(templates)
    rel = templates.active

    if params[:q].blank?
      if Docuseal.multitenant? ? current_account.testing? : current_account.linked_account_account
        shared_account_ids = [current_user.account_id]
        shared_account_ids << TemplateSharing::ALL_ID if !Docuseal.multitenant? && !current_account.testing?

        shared_template_ids = TemplateSharing.where(account_id: shared_account_ids).select(:template_id)

        rel = Template.where(
          Template.arel_table[:id].in(
            rel.where(folder_id: current_account.default_template_folder.id).select(:id).arel
               .union(:all, shared_template_ids.arel)
          )
        )
      else
        rel = rel.where(folder_id: current_account.default_template_folder.id)
      end
    end

    Templates.search(current_user, rel, params[:q])
  end

  def selected_order
    @selected_order ||=
      if cookies.permanent[:dashboard_templates_order].blank? ||
         (cookies.permanent[:dashboard_templates_order] == 'used_at' && can?(:manage, :countless))
        'created_at'
      else
        cookies.permanent[:dashboard_templates_order]
      end
  end

  def load_related_submissions
    @related_submissions = Submission.accessible_by(current_ability)
                                     .left_joins(:template)
                                     .where(archived_at: nil)
                                     .where(templates: { archived_at: nil })
                                     .preload(:template_accesses, :created_by_user,
                                              template: :author,
                                              submitters: :start_form_submission_events)

    @related_submissions = Submissions.search(current_user, @related_submissions, params[:q])
                                      .order(id: :desc)

    @related_submissions_pagy, @related_submissions = pagy_auto(@related_submissions, limit: 5)
  end
end
