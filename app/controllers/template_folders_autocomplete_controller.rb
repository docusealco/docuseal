# frozen_string_literal: true

class TemplateFoldersAutocompleteController < ApplicationController
  load_and_authorize_resource :template_folder, parent: false

  LIMIT = 100

  def index
    template_folders = @template_folders.joins(:templates).where(templates: { archived_at: nil }).distinct
    template_folders = TemplateFolders.search(template_folders, params[:q]).limit(LIMIT)

    render json: template_folders.as_json(only: %i[name archived_at])
  end
end
