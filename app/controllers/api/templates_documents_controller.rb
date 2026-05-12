# frozen_string_literal: true

module Api
  class TemplatesDocumentsController < ApiBaseController
    load_and_authorize_resource :template

    def update
      authorize!(:update, @template)

      Array.wrap(params[:documents]).each do |doc_params|
        if doc_params[:remove].in?([true, 'true'])
          remove_document(doc_params)
        elsif doc_params[:replace].in?([true, 'true'])
          replace_document(doc_params)
        else
          add_document(doc_params)
        end
      end

      @template.save!

      SearchEntries.enqueue_reindex(@template)
      WebhookUrls.enqueue_events(@template, 'template.updated')

      TemplateVersions.find_or_create_for(@template, author: current_user) if params[:revision].present?

      render json: Templates::SerializeForApi.call(@template)
    end

    private

    def remove_document(doc_params)
      position = doc_params[:position]&.to_i
      name = doc_params[:name]

      removed_schema = if position
                         @template.schema.delete_at(position)
                       elsif name
                         @template.schema.detect { |s| s['name'] == name }&.tap { |s| @template.schema.delete(s) }
                       end

      return unless removed_schema

      @template.fields.reject! do |field|
        field['areas']&.any? { |a| a['attachment_uuid'] == removed_schema['attachment_uuid'] }
      end
    end

    def replace_document(doc_params)
      position = doc_params[:position].to_i

      file = Api::DecodeDocumentFile.call(doc_params[:file], name: doc_params[:name])
      documents, = Templates::CreateAttachments.call(@template, { files: [file] }, extract_fields: true)
      document = documents.first

      return unless document

      old_schema = @template.schema[position]
      new_schema = { 'attachment_uuid' => document.uuid, 'name' => document.filename.base }

      if old_schema
        new_doc_has_fields =
          @template.fields.any? { |f| f['areas']&.any? { |a| a['attachment_uuid'] == document.uuid } }

        unless new_doc_has_fields
          @template.fields.each do |field|
            field['areas']&.each do |area|
              area['attachment_uuid'] = document.uuid if area['attachment_uuid'] == old_schema['attachment_uuid']
            end
          end
        end

        @template.schema[position] = new_schema
      else
        @template.schema << new_schema
      end
    end

    def add_document(doc_params)
      file = Api::DecodeDocumentFile.call(doc_params[:file], name: doc_params[:name])
      documents, = Templates::CreateAttachments.call(@template, { files: [file] }, extract_fields: true)
      document = documents.first

      return unless document

      new_schema = { 'attachment_uuid' => document.uuid, 'name' => doc_params[:name] || document.filename.base }
      position = doc_params[:position]&.to_i

      if position && position < @template.schema.size
        @template.schema.insert(position, new_schema)
      else
        @template.schema << new_schema
      end
    end
  end
end
