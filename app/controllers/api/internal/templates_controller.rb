# frozen_string_literal: true

module Api
  module Internal
    # Creates a Template under the calling account from one or more uploaded PDFs,
    # idempotent by `external_id`. Authenticates with the standard X-Auth-Token
    # (inherited from Api::ApiBaseController), so the template is always scoped to
    # `current_user.account`.
    #
    # The PDF-to-Template mechanism is the exact one the web uploader uses
    # (Templates::CreateAttachments), so the resulting template is identical to a
    # web-uploaded one and opens normally in the embed builder.
    class TemplatesController < Api::ApiBaseController
      def create
        existing = current_account.templates.find_by(external_id: params[:external_id])

        if existing
          authorize!(:read, existing)

          return render(json: { id: existing.id, external_id: existing.external_id })
        end

        template = build_template!

        render json: { id: template.id, external_id: template.external_id }
      end

      private

      def build_template!
        files = Array.wrap(params[:files]).compact_blank

        template = Template.new(
          account: current_account,
          author: current_user,
          external_id: params[:external_id],
          name: File.basename(files.first.original_filename, '.*')
        )

        authorize!(:create, template)

        Templates.maybe_assign_access(template)

        Template.transaction do
          template.folder = TemplateFolders.find_or_create_by_name(current_user, nil)
          template.save!

          documents, = Templates::CreateAttachments.call(template, { files: }, extract_fields: true)
          template.schema = documents.map { |doc| { 'attachment_uuid' => doc.uuid, 'name' => doc.filename.base } }

          if template.fields.blank?
            template.fields = Templates::ProcessDocument.normalize_attachment_fields(template, documents)

            template.schema.each { |item| item['pending_fields'] = true } if template.fields.present?
          end

          template.save!
        end

        WebhookUrls.enqueue_events(template, 'template.created')
        SearchEntries.enqueue_reindex(template)

        template
      end
    end
  end
end
