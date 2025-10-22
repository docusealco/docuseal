# frozen_string_literal: true

require 'tempfile'
require 'base64'

module Api
  class TemplatesController < ApiBaseController
    skip_authorization_check
    load_and_authorize_resource :template, except: [:pdf]

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
                                 .where(blob: { filename: ['0.png', '0.jpg'] })
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

      SearchEntries.enqueue_reindex(@template)
      enqueue_template_updated_webhooks

      render json: @template.as_json(only: %i[id updated_at])
    end

    def destroy
      if params[:permanently].in?(['true', true])
        @template.destroy!
      else
        @template.update!(archived_at: Time.current)
      end

      render json: @template.as_json(only: %i[id archived_at])
    end

    def pdf
      template = build_template
      fields_from_request = params[:fields] if params[:fields].present?

      template.save!

      begin
        documents = process_documents(template, params[:documents])
        schema = build_schema(documents)

        set_template_fields(template, fields_from_request, documents, schema) if template.fields.blank?

        template.update!(schema: schema)

        finalize_template_creation(template, documents)
      rescue StandardError => e
        template.destroy!
        raise e
      end
    rescue Templates::CreateAttachments::PdfEncrypted
      render json: { error: 'PDF encrypted', status: 'pdf_encrypted' }, status: :unprocessable_entity
    rescue StandardError => e
      Rollbar.error(e) if defined?(Rollbar)
      render json: { error: 'Unable to create template' }, status: :unprocessable_entity
    end

    private

    def process_documents(template, documents_params)
      return [] if documents_params.blank?

      documents_params.map.with_index do |doc_param, _index|
        (doc_param[:file].length / 4.0 * 3).ceil
        # Validate base64 string
        raise ArgumentError, 'Invalid base64 string format' unless doc_param[:file].match?(%r{\A[A-Za-z0-9+/]*={0,2}\z})

        # Decode base64 file data
        file_data = Base64.decode64(doc_param[:file])

        # Check if the decoded data looks like a PDF
        file_data[0..3] if file_data.size >= 4

        # Create a temporary file-like object
        file = Tempfile.new(['document', '.pdf'])
        file.binmode
        file.write(file_data)
        file.rewind

        # Add original filename
        file.define_singleton_method(:original_filename) { doc_param[:name] }
        file.define_singleton_method(:content_type) { 'application/pdf' }

        result = Templates::CreateAttachments.handle_pdf_or_image(template, file, file_data, {}, extract_fields: true)
        result
      ensure
        file&.close
        file&.unlink
      end
    end

    def build_template
      template = Template.new
      template.author = current_user
      template.name = params[:name] || 'Untitled Template'
      template.external_id = params[:external_id] if params[:external_id].present?
      template.source = :api
      template.submitters = params[:submitters] if params[:submitters].present?

      # Handle partnership vs account template creation
      if params[:external_partnership_id].present?
        partnership = Partnership.find_by(external_partnership_id: params[:external_partnership_id])
        if partnership.blank?
          raise ActiveRecord::RecordNotFound, "Partnership not found: #{params[:external_partnership_id]}"
        end

        template.partnership = partnership
        template.folder = TemplateFolders.find_or_create_by_name(
          current_user,
          params[:folder_name],
          partnership: partnership
        )
      else
        template.account = current_account
        template.folder = TemplateFolders.find_or_create_by_name(current_user, params[:folder_name])
      end

      template
    end

    def build_schema(documents)
      documents.map { |doc| { attachment_uuid: doc.uuid, name: doc.filename.base } }
    end

    def set_template_fields(template, fields_from_request, documents, schema)
      if fields_from_request.present?
        template.fields = map_request_fields_to_documents(fields_from_request, documents)
      else
        template.fields = Templates::ProcessDocument.normalize_attachment_fields(template, documents)
        schema.each { |item| item['pending_fields'] = true } if template.fields.present?
      end
    end

    def map_request_fields_to_documents(fields_from_request, documents)
      fields_from_request.map do |field|
        field_copy = field.dup
        if field_copy['areas'].present?
          field_copy['areas'] = field_copy['areas'].map do |area|
            area_copy = area.dup
            area_copy['attachment_uuid'] = documents.first.uuid if documents.any?
            area_copy
          end
        end
        field_copy
      end
    end

    def finalize_template_creation(template, documents)
      enqueue_template_created_webhooks(template)
      SearchEntries.enqueue_reindex(template)

      template_documents = template.documents.where(uuid: documents.map(&:uuid))
      result = Templates::SerializeForApi.call(template, template_documents)

      render json: result
    end

    def enqueue_template_created_webhooks(template)
      enqueue_template_webhooks(template, 'template.created', SendTemplateCreatedWebhookRequestJob)
    end

    def enqueue_template_updated_webhooks
      enqueue_template_webhooks(@template, 'template.updated', SendTemplateUpdatedWebhookRequestJob)
    end

    def enqueue_template_webhooks(template, event_type, job_class)
      return if template.account_id.blank?

      WebhookUrls.for_account_id(template.account_id, event_type).each do |webhook_url|
        job_class.perform_async('template_id' => template.id, 'webhook_url_id' => webhook_url.id)
      end
    end

    def filter_templates(templates, params)
      templates = Templates.search(current_user, templates, params[:q])
      templates = params[:archived].in?(['true', true]) ? templates.archived : templates.active
      templates = templates.where(external_id: params[:application_key]) if params[:application_key].present?
      templates = templates.where(external_id: params[:external_id]) if params[:external_id].present?
      templates = templates.where(slug: params[:slug]) if params[:slug].present?

      if params[:folder].present?
        folder = TemplateFolder.accessible_by(current_ability).find_by(name: params[:folder])

        templates = folder ? templates.where(folder:) : templates.none
      end

      templates
    end

    def template_params
      permitted_params = [
        :name,
        :external_id,
        :shared_link,
        {
          external_data_fields: {},
          submitters: [%i[name uuid is_requester invite_by_uuid optional_invite_by_uuid linked_to_uuid email]],
          fields: [[:uuid, :question_id, :submitter_uuid, :name, :type,
                    :required, :readonly, :default_value,
                    :title, :description,
                    { preferences: {},
                      conditions: [%i[field_uuid value action operation]],
                      options: [%i[value uuid answer_id]],
                      validation: %i[message pattern],
                      areas: [%i[x y w h cell_w attachment_uuid option_uuid answer_id page]] }]]
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
