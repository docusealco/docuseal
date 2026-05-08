# frozen_string_literal: true

module Api
  class TemplatesPdfController < ApiBaseController
    def create
      authorize!(:create, Template)

      @template = if params[:external_id].present?
                    current_account.templates.find_or_initialize_by(external_id: params[:external_id])
                  else
                    current_account.templates.new
                  end

      @template.assign_attributes(
        author: current_user,
        source: :api,
        name: params[:name].presence || extract_default_name,
        external_id: params[:external_id],
        team_id: @template.team_id || current_user.team_id
      )

      if params[:folder_name].present?
        @template.folder = TemplateFolders.find_or_create_by_name(current_user, params[:folder_name])
      end

      @template.save!

      process_documents

      Templates.maybe_assign_access(@template)

      @template.save!

      SearchEntries.enqueue_reindex(@template)
      WebhookUrls.enqueue_events(@template, @template.previously_new_record? ? 'template.created' : 'template.updated')

      render json: Templates::SerializeForApi.call(@template)
    end

    private

    def process_documents
      Array.wrap(params[:documents]).each do |doc_params|
        file = Api::DecodeDocumentFile.call(doc_params[:file], name: doc_params[:name] || 'document.pdf')
        documents, = Templates::CreateAttachments.call(@template, { files: [file] }, extract_fields: true)
        document = documents.first

        next unless document

        schema_entry = { 'attachment_uuid' => document.uuid, 'name' => doc_params[:name] || document.filename.base }
        @template.schema << schema_entry

        apply_explicit_fields(document, doc_params[:fields]) if doc_params[:fields].present?
      end
    end

    def apply_explicit_fields(document, fields_params)
      Array.wrap(fields_params).each do |field_params|
        role = field_params[:role] || 'First Party'

        submitter = @template.submitters.find { |s| s['name'] == role }
        unless submitter
          submitter = { 'name' => role, 'uuid' => SecureRandom.uuid }
          @template.submitters << submitter
        end

        areas = Array.wrap(field_params[:areas]).map do |area|
          {
            'attachment_uuid' => document.uuid,
            'x' => area[:x].to_f,
            'y' => area[:y].to_f,
            'w' => area[:w].to_f,
            'h' => area[:h].to_f,
            'page' => (area[:page].to_i - 1)
          }
        end

        field = {
          'uuid' => SecureRandom.uuid,
          'submitter_uuid' => submitter['uuid'],
          'name' => field_params[:name] || field_params[:type]&.humanize || 'Field',
          'type' => field_params[:type] || 'text',
          'required' => field_params[:required] != false,
          'areas' => areas
        }

        @template.fields << field
      end
    end

    def extract_default_name
      first_doc = Array.wrap(params[:documents]).first
      first_doc&.dig(:name) || 'Untitled'
    end
  end
end
