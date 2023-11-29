# frozen_string_literal: true

module Api
  class TemplatesController < ApiBaseController
    load_and_authorize_resource :template

    def index
      templates = Templates.search(@templates, params[:q])

      templates = params[:archived] ? templates.archived : templates.active
      templates = templates.where(application_key: params[:application_key]) if params[:application_key].present?
      templates = templates.joins(:folder).where(folder: { name: params[:folder] }) if params[:folder].present?

      templates = paginate(templates.preload(:author, documents_attachments: :blob))

      render json: {
        data: templates.as_json(serialize_params),
        pagination: {
          count: templates.size,
          next: templates.last&.id,
          prev: templates.first&.id
        }
      }
    end

    def show
      render json: @template.as_json(serialize_params)
    end

    def update
      if (folder_name = params.dig(:template, :folder_name))
        @template.folder = TemplateFolders.find_or_create_by_name(current_user, folder_name)
      end

      @template.update!(template_params)

      render json: @template.as_json(only: %i[id updated_at])
    end

    def destroy
      @template.update!(deleted_at: Time.current)

      render json: @template.as_json(only: %i[id deleted_at])
    end

    private

    def serialize_params
      {
        include: { author: { only: %i[id email first_name last_name] },
                   documents: { only: %i[id uuid], methods: %i[url filename] } }
      }
    end

    def template_params
      params.require(:template).permit(
        :name,
        schema: [%i[attachment_uuid name]],
        submitters: [%i[name uuid]],
        fields: [[:uuid, :submitter_uuid, :name, :type, :required, :readonly, :default_value,
                  { options: [%i[value uuid]], areas: [%i[x y w h cell_w attachment_uuid option_uuid page]] }]]
      )
    end
  end
end
