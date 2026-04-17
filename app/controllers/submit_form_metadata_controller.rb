# frozen_string_literal: true

class SubmitFormMetadataController < ApplicationController
  skip_before_action :authenticate_user!
  skip_authorization_check

  def index
    submitter = Submitter.find_by!(slug: params[:submit_form_slug])

    return head :not_found if submitter.declined_at? ||
                              submitter.completed_at? ||
                              submitter.submission.archived_at? ||
                              submitter.submission.expired? ||
                              submitter.submission.template&.archived_at? ||
                              submitter.account.archived_at? ||
                              !Submitters::AuthorizedForForm.call(submitter, current_user, request)

    submission = submitter.submission
    values = submission.submitters.reduce({}) { |acc, sub| acc.merge(sub.values) }
    schema = Submissions.filtered_conditions_schema(submission, values:, include_submitter_uuid: submitter.uuid)

    documents = schema.filter_map do |item|
      submission.schema_documents.find { |a| a.uuid == item['attachment_uuid'] }
    end

    ActiveRecord::Associations::Preloader.new(records: documents, associations: %i[blob record]).call

    text_runs = documents.to_h do |document|
      [
        document.uuid,
        DocumentMetadatas.find_or_create_for_document(document, account_id: document.record.account_id).text_runs
      ]
    end

    render json: { text_runs: }
  end
end
