# frozen_string_literal: true

class TemplateFoldersAutocompleteController < ApplicationController
  load_and_authorize_resource :template_folder, parent: false

  LIMIT = 100

  def index
    templates_query = Template.accessible_by(current_ability).where(archived_at: nil)

    template_folders = @template_folders.where(id: templates_query.select(:folder_id))
    template_folders = TemplateFolders.search(template_folders, params[:q]).limit(LIMIT)

    render json: template_folders.as_json(only: %i[name archived_at])
  end
end
