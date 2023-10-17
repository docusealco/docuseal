# frozen_string_literal: true

module Submitters
  module SerializeForApi
    module_function

    def call(submitter, with_template: false, with_events: false)
      ActiveRecord::Associations::Preloader.new(
        records: [submitter],
        associations: [documents_attachments: :blob, attachments_attachments: :blob]
      ).call

      values = SerializeForWebhook.build_values_array(submitter)
      documents = SerializeForWebhook.build_documents_array(submitter)

      submitter_name = (submitter.submission.template_submitters ||
                        submitter.submission.template.submitters).find { |e| e['uuid'] == submitter.uuid }['name']

      serialize_params = {
        include: {},
        only: %i[id slug uuid name email phone completed_at application_key
                 opened_at sent_at created_at updated_at]
      }

      serialize_params[:include][:template] = { only: %i[id name created_at updated_at] } if with_template

      if with_events
        serialize_params[:include][:submission_events] =
          { as: :events, only: %i[id submitter_id event_type event_timestamp] }
      end

      submitter.as_json(serialize_params)
               .merge('values' => values,
                      'documents' => documents,
                      'role' => submitter_name)
    end
  end
end
