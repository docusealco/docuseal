# frozen_string_literal: true

module Templates
  module ReplaceAttachments
    module_function

    # rubocop:disable Metrics
    def call(template, params = {}, extract_fields: false)
      documents = Templates::CreateAttachments.call(template, params, extract_fields:)
      submitter = template.submitters.first

      documents.each_with_index do |document, index|
        replaced_document_schema = template.schema[index]

        template.schema[index] = { attachment_uuid: document.uuid, name: document.filename.base }

        if replaced_document_schema
          template.fields.each do |field|
            next if field['areas'].blank?

            field['areas'].each do |area|
              if area['attachment_uuid'] == replaced_document_schema['attachment_uuid']
                area['attachment_uuid'] = document.uuid
              end
            end
          end
        end

        next if template.fields.any? { |f| f['areas']&.any? { |a| a['attachment_uuid'] == document.uuid } }
        next if submitter.blank? || document.metadata.dig('pdf', 'fields').blank?

        pdf_fields = document.metadata['pdf'].delete('fields').to_a
        pdf_fields.each { |f| f['submitter_uuid'] = submitter['uuid'] }

        if index.positive? && pdf_fields.present?
          preview_document = template.schema[index - 1]
          preview_document_last_field = template.fields.reverse.find do |f|
            f['areas']&.any? do |a|
              a['attachment_uuid'] == preview_document[:attachment_uuid]
            end
          end

          if preview_document_last_field
            last_preview_document_field_index = template.fields.find_index do |f|
              f['uuid'] == preview_document_last_field['uuid']
            end
          end

          if last_preview_document_field_index
            template.fields.insert(index, *pdf_fields)
          else
            template.fields += pdf_fields
          end
        elsif pdf_fields.present?
          template.fields += pdf_fields

          template.schema[index]['pending_fields'] = true
        end
      end

      documents
    end
    # rubocop:enable Metrics
  end
end
