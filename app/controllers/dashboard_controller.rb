# frozen_string_literal: true

class DashboardController < ApplicationController
  skip_before_action :authenticate_user!, only: %i[index]

  before_action :maybe_redirect_product_url
  before_action :maybe_render_landing

  load_and_authorize_resource :template_folder, parent: false
  load_and_authorize_resource :template, parent: false

  SHOW_TEMPLATES_FOLDERS_THRESHOLD = 9
  TEMPLATES_PER_PAGE = 12
  FOLDERS_PER_PAGE = 18

  def index
    @template_folders = filter_template_folders(@template_folders)

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

      items =
        if @template_folders.size < 4
          TEMPLATES_PER_PAGE
        else
          (@template_folders.size < 7 ? 9 : 6)
        end

      @pagy, @templates = pagy(@templates, items:)
    end
  end

  private

  def filter_template_folders(template_folders)
    rel = template_folders.joins(:active_templates)
                          .order(id: :desc)
                          .distinct

    TemplateFolders.search(rel, params[:q])
  end

  def filter_templates(templates)
    rel = templates.active.preload(:author).order(id: :desc)
                   .where(folder_id: current_account.default_template_folder.id)

    Templates.search(rel, params[:q])
  end

  def maybe_redirect_product_url
    return if !Docuseal.multitenant? || signed_in?

    redirect_to Docuseal::PRODUCT_URL, allow_other_host: true
  end

  def maybe_render_landing
    return if signed_in?

    render 'pages/landing'
  end
end
