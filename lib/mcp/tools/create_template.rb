# frozen_string_literal: true

module Mcp
  module Tools
    module CreateTemplate
      SCHEMA = {
        name: 'create_template',
        title: 'Create Template',
        description: 'Create a template from a PDF. Provide a URL or base64-encoded file content.',
        inputSchema: {
          type: 'object',
          properties: {
            url: {
              type: 'string',
              description: 'URL of the document file to upload'
            },
            file: {
              type: 'string',
              description: 'Base64-encoded file content'
            },
            filename: {
              type: 'string',
              description: 'Filename with extension (required when using file)'
            },
            name: {
              type: 'string',
              description: 'Template name (defaults to filename)'
            }
          }
        },
        annotations: {
          readOnlyHint: false,
          destructiveHint: false,
          idempotentHint: false,
          openWorldHint: false
        }
      }.freeze

      module_function

      # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      def call(arguments, current_user, current_ability)
        current_ability.authorize!(:create, Template.new(account_id: current_user.account_id, author: current_user))

        account = current_user.account

        if arguments['file'].present?
          tempfile = Tempfile.new
          tempfile.binmode
          tempfile.write(Base64.decode64(arguments['file']))
          tempfile.rewind

          filename = arguments['filename'] || 'document.pdf'
        elsif arguments['url'].present?
          tempfile = Tempfile.new
          tempfile.binmode
          tempfile.write(DownloadUtils.call(arguments['url'], validate: true).body)
          tempfile.rewind

          filename = File.basename(URI.decode_www_form_component(arguments['url']))
        else
          return { content: [{ type: 'text', text: 'Provide either url or file' }], isError: true }
        end

        file = ActionDispatch::Http::UploadedFile.new(
          tempfile:,
          filename:,
          type: Marcel::MimeType.for(tempfile)
        )

        template = Template.new(
          account:,
          author: current_user,
          folder: account.default_template_folder,
          name: arguments['name'].presence || File.basename(filename, '.*')
        )

        template.save!

        documents, = Templates::CreateAttachments.call(template, { files: [file] }, extract_fields: true)
        schema = documents.map { |doc| { attachment_uuid: doc.uuid, name: doc.filename.base } }

        if template.fields.blank?
          template.fields = Templates::ProcessDocument.normalize_attachment_fields(template, documents)
        end

        template.update!(schema:)

        WebhookUrls.enqueue_events(template, 'template.created')

        SearchEntries.enqueue_reindex(template)

        {
          content: [
            {
              type: 'text',
              text: {
                id: template.id,
                name: template.name,
                edit_url: Rails.application.routes.url_helpers.edit_template_url(template,
                                                                                 **Docuseal.default_url_options)
              }.to_json
            }
          ]
        }
      end
    end
    # rubocop:enable Metrics/AbcSize, Metrics/MethodLength
  end
end
