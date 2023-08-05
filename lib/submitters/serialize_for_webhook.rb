# frozen_string_literal: true

module Submitters
  module SerializeForWebhook
    module_function

    def call(submitter)
      values = build_values_array(submitter)
      documents = build_documents_array(submitter)

      submitter_name = submitter.submission.template_submitters.find { |e| e['uuid'] == submitter.uuid }['name']

      submitter.as_json(include: [template: { only: %i[id name created_at updated_at] }])
               .except('uuid', 'values', 'slug')
               .merge('values' => values,
                      'documents' => documents,
                      'submitter_name' => submitter_name)
    end

    def build_values_array(submitter)
      fields_index = submitter.submission.template_fields.index_by { |e| e['uuid'] }
      attachments_index = submitter.attachments.preload(:blob).index_by(&:uuid)
      submitter_field_counters = Hash.new { 0 }

      submitter.values.map do |uuid, value|
        field = fields_index[uuid]
        submitter_field_counters[field['type']] += 1

        field_name =
          field['name'].presence || "#{field['type'].titleize} Field #{submitter_field_counters[field['type']]}"

        value = fetch_field_value(field, value, attachments_index)

        { field: field_name, value: }
      end
    end

    def build_documents_array(submitter)
      submitter.documents.preload(:blob).map do |attachment|
        { name: attachment.filename.base, url: attachment.url }
      end
    end

    def fetch_field_value(field, value, attachments_index)
      if field['type'].in?(%w[image signature])
        attachments_index[value]&.url
      elsif field['type'] == 'file'
        Array.wrap(value).compact_blank.filter_map { |e| attachments_index[e]&.url }
      else
        value
      end
    end
  end
end
