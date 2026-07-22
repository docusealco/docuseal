# frozen_string_literal: true

module Mcp
  class CreateTemplateController < McpBaseController
    SCHEMA = {
      name: 'create_template',
      title: 'Create Template',
      description: 'Create a document template. Provide a URL to upload a PDF/DOCX file, or provide only a name ' \
                   'to create an empty template and receive an edit URL where the file can be uploaded via the UI.',
      inputSchema: {
        type: 'object',
        properties: {
          name: {
            type: 'string',
            description: 'Template name (used as the template name and required when url is not provided)'
          },
          url: {
            type: 'string',
            description: 'Optional URL of a PDF or DOCX file to upload. If omitted, an empty template is ' \
                         'created and the returned edit_url can be used to upload a file via the UI.'
          }
        },
        required: %w[name]
      },
      annotations: {
        readOnlyHint: false,
        destructiveHint: false,
        idempotentHint: false,
        openWorldHint: true
      }
    }.freeze

    # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    def call
      account = current_user.account

      @template = Template.new(
        account:,
        author: current_user,
        folder: account.default_template_folder,
        source: :mcp,
        name: mcp_params['name'].to_s.presence || 'New Template',
        fields: [],
        schema: []
      )

      authorize!(:create, @template)

      if mcp_params['url'].present?
        tempfile = Tempfile.new
        tempfile.binmode
        tempfile.write(DownloadUtils.call(mcp_params['url'], validate: true).body)
        tempfile.rewind

        filename = File.basename(URI.decode_www_form_component(mcp_params['url']))

        file = ActionDispatch::Http::UploadedFile.new(
          tempfile:,
          filename:,
          type: Marcel::MimeType.for(tempfile)
        )

        @template.name = mcp_params['name'].presence || File.basename(filename, '.*')
        @template.save!

        documents, = Templates::CreateAttachments.call(@template, { files: [file] }, extract_fields: true)
        schema = documents.map { |doc| { attachment_uuid: doc.uuid, name: doc.filename.base } }

        if @template.fields.blank?
          @template.fields = Templates::ProcessDocument.normalize_attachment_fields(@template, documents)
        end

        @template.update!(schema:)
      else
        @template.save!
      end

      WebhookUrls.enqueue_events(@template, 'template.created')

      SearchEntries.enqueue_reindex(@template)

      render_tool_result(
        id: @template.id,
        name: @template.name,
        edit_url: edit_template_url(@template)
      )
    end
    # rubocop:enable Metrics/AbcSize, Metrics/MethodLength
  end
end
