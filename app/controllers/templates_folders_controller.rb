# frozen_string_literal: true

class TemplatesFoldersController < ApplicationController
  load_and_authorize_resource :template

  def edit; end

  def update
    @template.folder = TemplateFolders.find_or_create_by_name(current_user, params[:name])

    if @template.save
      redirect_back(fallback_location: template_path(@template), notice: I18n.t('document_template_has_been_moved'))
    else
      redirect_back(fallback_location: template_path(@template), notice: I18n.t('unable_to_move_template_into_folder'))
    end
  end

  private

  def template_folder_params
    params.require(:template_folder).permit(:name)
  end
end
