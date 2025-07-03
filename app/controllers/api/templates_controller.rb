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

      WebhookUrls.for_account_id(@template.account_id, 'template.updated').each do |webhook_url|
        SendTemplateUpdatedWebhookRequestJob.perform_async('template_id' => @template.id,
                                                           'webhook_url_id' => webhook_url.id)
      end

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
      template = Template.new
      template.account = current_account
      template.author = current_user
      template.folder = TemplateFolders.find_or_create_by_name(current_user, params[:folder_name])
      template.name = params[:name] || 'Untitled Template'
      template.external_id = params[:external_id] if params[:external_id].present?
      template.source = :api

      template.save!

            begin
        puts "DEBUG: Starting document processing..."
        documents = process_documents(template, params[:documents])
        puts "DEBUG: Documents processed: #{documents.count}"

        schema = documents.map { |doc| { attachment_uuid: doc.uuid, name: doc.filename.base } }
        puts "DEBUG: Schema created: #{schema}"

        if template.fields.blank?
          puts "DEBUG: Processing fields..."
          template.fields = Templates::ProcessDocument.normalize_attachment_fields(template, documents)
          schema.each { |item| item['pending_fields'] = true } if template.fields.present?
          puts "DEBUG: Fields processed: #{template.fields.count}"
        end

        puts "DEBUG: Updating template schema..."
        template.update!(schema: schema)
        puts "DEBUG: Template schema updated"

        puts "DEBUG: Enqueueing webhooks..."
        enqueue_template_created_webhooks(template)
        puts "DEBUG: Webhooks enqueued"

        puts "DEBUG: Enqueueing search reindex..."
        SearchEntries.enqueue_reindex(template)
        puts "DEBUG: Search reindex enqueued"

        # Get the documents for serialization
        puts "DEBUG: Getting template documents for serialization..."
        template_documents = template.documents.where(uuid: documents.map(&:uuid))
        puts "DEBUG: Template documents found: #{template_documents.count}"

        puts "DEBUG: Serializing template..."
        result = Templates::SerializeForApi.call(template, template_documents)
        puts "DEBUG: Template serialized successfully"

        render json: result
      rescue StandardError => e
        puts "DEBUG: ERROR OCCURRED: #{e.class} - #{e.message}"
        puts "DEBUG: Backtrace: #{e.backtrace.first(5).join("\n")}"
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
      puts "DEBUG: process_documents called with #{documents_params&.count || 0} documents"
      return [] if documents_params.blank?

      documents_params.map.with_index do |doc_param, index|
        puts "DEBUG: Processing document #{index + 1}: #{doc_param[:name]}"
        puts "DEBUG: Base64 string length: #{doc_param[:file].length}"
        puts "DEBUG: Base64 string first 100 chars: #{doc_param[:file][0..99]}"
        puts "DEBUG: Base64 string last 100 chars: #{doc_param[:file][-100..-1]}"

        # Check if the base64 string looks truncated
        expected_length = (doc_param[:file].length / 4.0 * 3).ceil
        puts "DEBUG: Expected decoded size: #{expected_length} bytes"
        puts "DEBUG: Base64 string ends with padding: #{doc_param[:file].end_with?('==') || doc_param[:file].end_with?('=')}"
        puts "DEBUG: Base64 string length is multiple of 4: #{doc_param[:file].length % 4 == 0}"

        # Validate base64 string
        unless doc_param[:file].match?(/\A[A-Za-z0-9+\/]*={0,2}\z/)
          puts "DEBUG: ERROR: Invalid base64 string format"
          raise ArgumentError, "Invalid base64 string format"
        end

        # Decode base64 file data
        file_data = Base64.decode64(doc_param[:file])
        puts "DEBUG: File data decoded, size: #{file_data.size} bytes"
        puts "DEBUG: First 50 bytes as hex: #{file_data[0..49].unpack('H*').first}"
        puts "DEBUG: First 50 bytes as string: #{file_data[0..49].inspect}"

        # Check if the decoded data looks like a PDF
        if file_data.size >= 4
          pdf_header = file_data[0..3]
          puts "DEBUG: PDF header: #{pdf_header.inspect}"
          puts "DEBUG: Is PDF header valid: #{pdf_header == '%PDF'}"
        end

        # Create a temporary file-like object
        file = Tempfile.new(['document', '.pdf'])
        file.binmode
        file.write(file_data)
        file.rewind

        # Add original filename
        file.define_singleton_method(:original_filename) { doc_param[:name] }
        file.define_singleton_method(:content_type) { 'application/pdf' }

        puts "DEBUG: Calling Templates::CreateAttachments.handle_pdf_or_image..."
        # Process the document using the existing service
        result = Templates::CreateAttachments.handle_pdf_or_image(template, file, file_data, {}, extract_fields: true)
        puts "DEBUG: Document processed successfully: #{result.class}"
        result
      ensure
        file&.close
        file&.unlink
      end
    end

    def enqueue_template_created_webhooks(template)
      WebhookUrls.for_account_id(template.account_id, 'template.created').each do |webhook_url|
        SendTemplateCreatedWebhookRequestJob.perform_async('template_id' => template.id,
                                                           'webhook_url_id' => webhook_url.id)
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
          submitters: [%i[name uuid is_requester invite_by_uuid optional_invite_by_uuid linked_to_uuid email]],
          fields: [[:uuid, :submitter_uuid, :name, :type,
                    :required, :readonly, :default_value,
                    :title, :description,
                    { preferences: {},
                      conditions: [%i[field_uuid value action operation]],
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
