# frozen_string_literal: true

class TemplatesDashboardController < ApplicationController
  load_and_authorize_resource :template_folder, parent: false
  load_and_authorize_resource :template, parent: false

  SHOW_TEMPLATES_FOLDERS_THRESHOLD = 9
  TEMPLATES_PER_PAGE = 12
  FOLDERS_PER_PAGE = 18
  LAST_USED_SQL = <<~SQL.squish
    GREATEST(
      COALESCE(MAX(templates.updated_at), '1970-01-01'),
      COALESCE(MAX(submissions.created_at), '1970-01-01')
    )
  SQL

  def index
    @template_folders = @template_folders.where(id: @templates.active.select(:folder_id))

    @template_folders = TemplateFolders.search(@template_folders, params[:q])
    @template_folders = sort_template_folders(@template_folders)

    @pagy, @template_folders = pagy(
      @template_folders,
      items: FOLDERS_PER_PAGE,
      page: @template_folders.count > SHOW_TEMPLATES_FOLDERS_THRESHOLD ? params[:page] : 1
    )

    if @pagy.count > SHOW_TEMPLATES_FOLDERS_THRESHOLD
      @templates = @templates.none
    else
      @template_folders = @template_folders.reject { |e| e.name == TemplateFolder::DEFAULT_NAME }
      @templates = filter_templates(@templates)
      @templates = sort_templates(@templates)

      limit =
        if @template_folders.size < 4
          TEMPLATES_PER_PAGE
        else
          (@template_folders.size < 7 ? 9 : 6)
        end

      @pagy, @templates = pagy(@templates, limit:)
    end
  end

  private

  def filter_templates(templates)
    rel = templates.active.preload(:author, :template_accesses)

    if params[:q].blank?
      if Docuseal.multitenant? && !current_account.testing?
        rel = rel.where(folder_id: current_account.default_template_folder.id)
      else
        shared_template_ids =
          TemplateSharing.where(account_id: [current_account.id, TemplateSharing::ALL_ID]).select(:template_id)

        rel = rel.where(folder_id: current_account.default_template_folder.id).or(rel.where(id: shared_template_ids))
      end
    end

    Templates.search(rel, params[:q])
  end

  def sort_template_folders(template_folders)
    return template_folders.order(id: :desc) if params[:q].present?

    case cookies.permanent[:dashboard_templates_order]
    when 'recently_used'
      sorted_folders =
        template_folders.left_joins(templates: :submissions)
                        .select("template_folders.*, #{LAST_USED_SQL} AS last_used_at")
                        .group('template_folders.id')
                        .order(Arel.sql("#{LAST_USED_SQL} DESC NULLS LAST"))

      TemplateFolder.from(sorted_folders, :template_folders)
    when 'name'
      template_folders.order(name: :asc)
    else
      template_folders.order(id: :desc)
    end
  end

  def sort_templates(templates)
    return templates.order(id: :desc) if params[:q].present?

    case cookies.permanent[:dashboard_templates_order]
    when 'recently_used'
      sorted_templates =
        templates.left_joins(:submissions)
                 .select("templates.*, #{LAST_USED_SQL} AS last_used_at")
                 .group('templates.id')
                 .order(Arel.sql("#{LAST_USED_SQL} DESC NULLS LAST"))

      Template.from(sorted_templates, :templates)
    when 'name'
      templates.order(name: :asc)
    else
      templates.order(id: :desc)
    end
  end
end
