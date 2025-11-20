# frozen_string_literal: true

class TemplateFoldersAutocompleteController < ApplicationController
  load_and_authorize_resource :template_folder, parent: false

  LIMIT = 30

  def index
    parent_name, name =
      if params[:parent_name].present?
        [params[:parent_name], params[:q]]
      else
        params[:q].to_s.split(' /', 2).map(&:squish)
      end

    if name
      parent_folder = @template_folders.find_by(name: parent_name, parent_folder_id: nil)
    else
      name = parent_name
    end

    template_folders = TemplateFolders.filter_active_folders(@template_folders.where(parent_folder:),
                                                             Template.accessible_by(current_ability))

    name = name.to_s.downcase

    template_folders = TemplateFolders.search(template_folders, name).order(id: :desc).limit(LIMIT)

    render json: template_folders.preload(:parent_folder)
                                 .sort_by { |e| e.name.downcase.index(name) || Float::MAX }
                                 .as_json(only: %i[name archived_at], methods: %i[full_name])
  end
end
