# frozen_string_literal: true

class TemplatesDashboardController < ApplicationController
  load_and_authorize_resource :template_folder, parent: false
  load_and_authorize_resource :template, parent: false

  SHOW_TEMPLATES_FOLDERS_THRESHOLD = 9
  TEMPLATES_PER_PAGE = 12
  FOLDERS_PER_PAGE = 18

  helper_method :selected_order

  def index
    @default_folder = current_account.default_template_folder

    @template_folders =
      TemplateFolders.filter_active_folders(@template_folders.where(parent_folder_id: nil), @templates)

    @template_folders = @template_folders.where.not(id: @default_folder.id) if params[:q].blank?

    @template_folders = TemplateFolders.search(@template_folders, params[:q])
    @template_folders = TemplateFolders.sort(@template_folders, current_user, selected_order)

    @shared_templates = Templates.shared(current_user).active

    @pagy, @template_folders, @show_default_folder, @show_shared_folder, @show_shared_inline =
      load_folders(@template_folders, @templates, @shared_templates)

    if @pagy.count > SHOW_TEMPLATES_FOLDERS_THRESHOLD
      @templates = @templates.none
    else
      if @show_shared_inline
        @templates = @shared_templates.preload(:template_sharings)
      else
        @templates = @templates.active
        @templates = @templates.where(folder_id: @default_folder.id) if params[:q].blank?
      end

      @pagy, @templates = load_templates(@templates.select_for_list, @pagy.count,
                                         show_shared_inline: @show_shared_inline)

      if params[:q].present? && @templates.blank?
        @related_submissions_pagy, @related_submissions = load_related_submissions
      end
    end
  end

  private

  def load_templates(templates, folders_count, show_shared_inline: false)
    templates = templates.preload(:author, :template_accesses)

    templates =
      if show_shared_inline
        Templates.search_shared(current_user, templates, params[:q])
      else
        Templates.search(current_user, templates, params[:q])
      end

    templates = Templates::Order.call(templates, current_user, selected_order)

    limit =
      if folders_count < 4
        TEMPLATES_PER_PAGE
      else
        (folders_count < 7 ? 9 : 6)
      end

    pagy_auto(templates, limit:)
  end

  def load_folders(template_folders, templates, shared_templates)
    if params[:q].present?
      pagy(template_folders, limit: FOLDERS_PER_PAGE,
                             page: template_folders.count > SHOW_TEMPLATES_FOLDERS_THRESHOLD ? params[:page] : 1)
    else
      load_folders_with_pinned(template_folders, templates, shared_templates)
    end
  end

  def load_folders_with_pinned(template_folders, templates, shared_templates)
    folders_count = template_folders.count

    shared_exists = shared_templates.exists?
    default_has_templates = templates.active.exists?(folder_id: current_account.default_template_folder.id)

    show_inline_folders =
      folders_count + (shared_exists && default_has_templates ? 1 : 0) <= SHOW_TEMPLATES_FOLDERS_THRESHOLD

    show_shared_inline = shared_exists && !default_has_templates && show_inline_folders

    show_shared_in_grid = shared_exists && !show_shared_inline
    show_default_in_grid = !show_inline_folders && default_has_templates

    pinned_count = (show_default_in_grid ? 1 : 0) + (show_shared_in_grid ? 1 : 0)

    pagy = Pagy::Offset.new(count: folders_count + pinned_count,
                            page: show_inline_folders ? 1 : [params[:page].to_s.to_i, 1].max,
                            limit: FOLDERS_PER_PAGE,
                            raise_range_error: true)

    show_default_folder = show_default_in_grid && pagy.page == 1
    show_shared_folder = show_shared_in_grid && pagy.page == 1

    folder_offset = pagy.page == 1 ? 0 : pagy.offset - pinned_count
    folder_limit = pagy.page == 1 ? FOLDERS_PER_PAGE - pinned_count : FOLDERS_PER_PAGE

    template_folders = template_folders.offset(folder_offset).limit(folder_limit)

    [pagy, template_folders, show_default_folder, show_shared_folder, show_shared_inline]
  end

  def selected_order
    @selected_order ||=
      if can?(:manage, :countless)
        'created_at'
      else
        cookies.permanent[:dashboard_templates_order].presence || 'created_at'
      end
  end

  def load_related_submissions
    related_submissions = Submission.accessible_by(current_ability)
                                    .left_joins(:template)
                                    .where(archived_at: nil)
                                    .where(templates: { archived_at: nil })
                                    .preload(:template_accesses, :created_by_user,
                                             template: :author,
                                             submitters: :start_form_submission_events)

    related_submissions = Submissions.search(current_user, related_submissions, params[:q])
                                     .order(id: :desc)

    pagy_auto(related_submissions.select_for_list, limit: 5)
  end
end
