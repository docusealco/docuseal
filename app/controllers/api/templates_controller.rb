# frozen_string_literal: true

module Api
  class TemplatesController < ApiBaseController
    load_and_authorize_resource :template

    def index
      templates = filter_templates(@templates, params)

      templates = paginate(templates.preload(:author, folder: :parent_folder))

      schema_documents, dynamic_documents, preview_image_attachments = preload_relations(templates)

      expires_at = Accounts.link_expires_at(current_account)

      render json: {
        data: templates.map do |t|
          Templates::SerializeForApi.call(t,
                                          schema_documents: schema_documents.select { |e| e.record_id == t.id },
                                          dynamic_documents:,
                                          preview_image_attachments:,
                                          expires_at:)
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

      if archived.in?([true, false]) && current_ability.can?(:destroy, @template)
        @template.archived_at = archived == true ? Time.current : nil
      end

      @template.update!(template_params)

      SearchEntries.enqueue_reindex(@template)

      WebhookUrls.enqueue_events(@template, 'template.updated')

      if @template.saved_change_to_archived_at? && @template.archived_at?
        WebhookUrls.enqueue_events(@template, 'template.archived')
      end

      render json: @template.as_json(only: %i[id updated_at])
    end

    def destroy
      if params[:permanently].in?(['true', true])
        @template.destroy!
      else
        @template.update!(archived_at: Time.current)

        WebhookUrls.enqueue_events(@template, 'template.archived')
      end

      render json: @template.as_json(only: %i[id archived_at])
    end

    private

    def preload_relations(templates)
      schema_documents =
        ActiveStorage::Attachment.where(record_id: templates.map(&:id),
                                        record_type: 'Template',
                                        name: :documents,
                                        uuid: templates.flat_map { |t| t.schema.pluck('attachment_uuid') })
                                 .preload(:blob)

      dynamic_document_uuids =
        templates.flat_map { |t| t.schema.select { |item| item['dynamic'] }.pluck('attachment_uuid') }

      dynamic_documents =
        if dynamic_document_uuids.present?
          DynamicDocument.where(template: templates.map(&:id))
                         .where(uuid: dynamic_document_uuids)
                         .preload(current_version: { document_attachment: :blob })
                         .select(:id, :uuid, :template_id, :sha1, :created_at, :updated_at)
        else
          DynamicDocument.none
        end

      preview_attachment_ids =
        schema_documents.map(&:id) + dynamic_documents.filter_map { |d| d.current_version&.document_attachment&.id }

      preview_image_attachments =
        ActiveStorage::Attachment.joins(:blob)
                                 .where(blob: { filename: ['0.png', '0.jpg'] })
                                 .where(record_id: preview_attachment_ids,
                                        record_type: 'ActiveStorage::Attachment',
                                        name: :preview_images)
                                 .preload(:blob)

      [schema_documents, dynamic_documents, preview_image_attachments]
    end

    def filter_templates(templates, params)
      templates = Templates.search(current_user, templates, params[:q])
      templates = params[:archived].in?(['true', true]) ? templates.archived : templates.active
      templates = templates.where(external_id: params[:application_key]) if params[:application_key].present?
      templates = templates.where(external_id: params[:external_id]) if params[:external_id].present?
      templates = templates.where(slug: params[:slug]) if params[:slug].present?

      if params[:folder].present?
        folders = TemplateFolders.filter_by_full_name(TemplateFolder.accessible_by(current_ability), params[:folder])

        templates = templates.where(folder_id: folders.pluck(:id))
      end

      templates
    end

    def template_params
      permitted_params = [
        :name,
        :external_id,
        :shared_link,
        {
          submitters: [%i[name uuid is_requester invite_by_uuid invite_via_field_uuid
                          optional_invite_by_uuid linked_to_uuid email order]],
          fields: [[:uuid, :submitter_uuid, :name, :type,
                    :required, :readonly, :default_value,
                    :title, :description, :prefillable,
                    { preferences: {},
                      default_value: [],
                      conditions: [%i[field_uuid value action operation]],
                      options: [%i[value uuid]],
                      validation: %i[message pattern min max step],
                      areas: [%i[uuid x y w h cell_w attachment_uuid option_uuid page]] }]]
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
