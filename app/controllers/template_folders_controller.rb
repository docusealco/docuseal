# frozen_string_literal: true

class TemplateFoldersController < ApplicationController
  load_and_authorize_resource :template_folder

  def show
    @templates = @template_folder.templates.active.preload(:author).order(id: :desc)
    @templates = Templates.search(@templates, params[:q])

    @pagy, @templates = pagy(@templates, limit: 12)
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
