# frozen_string_literal: true

class TemplateFoldersController < ApplicationController
  load_and_authorize_resource :template_folder

  helper_method :selected_order

  TEMPLATES_PER_PAGE = 12
  FOLDERS_PER_PAGE = 18

  def show
    @templates = Template.active.accessible_by(current_ability)
                         .where(folder: [@template_folder, *(params[:q].present? ? @template_folder.subfolders : [])])
                         .preload(:author, :template_accesses)

    @template_folders =
      @template_folder.subfolders.where(id: Template.accessible_by(current_ability).active.select(:folder_id))

    @template_folders = TemplateFolders.search(@template_folders, params[:q])
    @template_folders = TemplateFolders.sort(@template_folders, current_user, selected_order)

    if @templates.exists?
      @templates = Templates.search(current_user, @templates, params[:q])
      @templates = Templates::Order.call(@templates, current_user, selected_order)

      limit =
        if @template_folders.size < 4
          TEMPLATES_PER_PAGE
        else
          (@template_folders.size < 7 ? 9 : 6)
        end

      @pagy, @templates = pagy_auto(@templates, limit:)

      load_related_submissions if params[:q].present? && @templates.blank?
    else
      @pagy, @template_folders = pagy(@template_folders, limit: FOLDERS_PER_PAGE)

      @templates = @templates.none
    end
  end

  def edit; end

  def update
    if @template_folder != current_account.default_template_folder &&
       @template_folder.update(template_folder_params)
      redirect_to folder_path(@template_folder), notice: I18n.t('folder_name_has_been_updated')
    else
      redirect_to folder_path(@template_folder), alert: I18n.t('unable_to_rename_folder')
    end
  end

  private

  def selected_order
    @selected_order ||=
      if cookies.permanent[:dashboard_templates_order].blank? ||
         (cookies.permanent[:dashboard_templates_order] == 'used_at' && can?(:manage, :countless))
        'created_at'
      else
        cookies.permanent[:dashboard_templates_order]
      end
  end

  def template_folder_params
    params.require(:template_folder).permit(:name)
  end

  def load_related_submissions
    @related_submissions =
      Submission.accessible_by(current_ability)
                .where(archived_at: nil)
                .where(template_id: current_account.templates.active
                                                   .where(folder: [@template_folder, *@template_folder.subfolders])
                                                   .select(:id))
                .preload(:template_accesses, :created_by_user,
                         template: :author,
                         submitters: :start_form_submission_events)

    @related_submissions = Submissions.search(current_user, @related_submissions, params[:q])
                                      .order(id: :desc)

    @related_submissions_pagy, @related_submissions = pagy_auto(@related_submissions, limit: 5)
  end
end
