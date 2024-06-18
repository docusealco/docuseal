# frozen_string_literal: true

module Api
  class TemplatesController < ApiBaseController
    load_and_authorize_resource :template

    def index
      templates = filter_templates(@templates, params)

      templates = paginate(templates.preload(:author, :folder))

      schema_documents =
        ActiveStorage::Attachment.where(record_id: templates.map(&:id),
                                        record_type: 'Template',
                                        name: :documents,
                                        uuid: templates.flat_map { |t| t.schema.pluck('attachment_uuid') })
                                 .preload(:blob)

      preview_image_attachments =
        ActiveStorage::Attachment.joins(:blob)
                                 .where(blob: { filename: '0.jpg' })
                                 .where(record_id: schema_documents.map(&:id),
                                        record_type: 'ActiveStorage::Attachment',
                                        name: :preview_images)
                                 .preload(:blob)

      render json: {
        data: templates.map do |t|
          Templates::SerializeForApi.call(
            t,
            schema_documents.select { |e| e.record_id == t.id },
            preview_image_attachments
          )
        end,
        pagination: {
          count: templates.size,
          next: templates.last&.id,
          prev: templates.first&.id
        }
      }
    end

    def show
      render json: Templates::SerializeForApi.call(@template)
    end

    def update
      if (folder_name = params[:folder_name] || params.dig(:template, :folder_name))
        @template.folder = TemplateFolders.find_or_create_by_name(current_user, folder_name)
      end

      Array.wrap(params[:roles].presence || params.dig(:template, :roles).presence).each_with_index do |role, index|
        if (item = @template.submitters[index])
          item['name'] = role
        else
          @template.submitters << { 'name' => role, 'uuid' => SecureRandom.uuid }
        end
      end

      archived = params.key?(:archived) ? params[:archived] : params.dig(:template, :archived)

      if archived.in?([true, false])
        @template.archived_at = archived == true ? Time.current : nil
      end

      @template.update!(template_params)

      SendTemplateUpdatedWebhookRequestJob.perform_async('template_id' => @template.id)

      render json: @template.as_json(only: %i[id updated_at])
    end

    def destroy
      if params[:permanently] == 'true'
        @template.destroy!
      else
        @template.update!(archived_at: Time.current)
      end

      render json: @template.as_json(only: %i[id archived_at])
    end

    private

    def filter_templates(templates, params)
      templates = Templates.search(templates, params[:q])
      templates = params[:archived] ? templates.archived : templates.active
      templates = templates.where(external_id: params[:application_key]) if params[:application_key].present?
      templates = templates.where(external_id: params[:external_id]) if params[:external_id].present?
      templates = templates.joins(:folder).where(folder: { name: params[:folder] }) if params[:folder].present?

      templates
    end

    def template_params
      permitted_params = [
        :name,
        {
          submitters: [%i[name uuid]],
          fields: [[:uuid, :submitter_uuid, :name, :type,
                    :required, :readonly, :default_value,
                    :title, :description,
                    { preferences: {},
                      conditions: [%i[field_uuid value action]],
                      options: [%i[value uuid]],
                      validation: %i[message pattern],
                      areas: [%i[x y w h cell_w attachment_uuid option_uuid page]] }]]
        }
      ]

      if params.key?(:template)
        params.require(:template).permit(permitted_params)
      else
        params.permit(permitted_params)
      end
    end
  end
end
