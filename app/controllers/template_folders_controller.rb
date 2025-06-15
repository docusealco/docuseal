# frozen_string_literal: true

class TemplateFoldersController < ApplicationController
  load_and_authorize_resource :template_folder

  def show
    @templates = @template_folder.templates.active.accessible_by(current_ability)
                                 .preload(:author, :template_accesses)
    @templates = Templates.search(current_user, @templates, params[:q])
    @templates = Templates::Order.call(@templates, current_user, cookies.permanent[:dashboard_templates_order])

    @pagy, @templates = pagy_auto(@templates, limit: 12)
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

  def template_folder_params
    params.require(:template_folder).permit(:name)
  end
end
