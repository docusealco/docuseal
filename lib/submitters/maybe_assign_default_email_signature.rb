# frozen_string_literal: true

module Submitters
  module MaybeAssignDefaultEmailSignature
    module_function

    def call(submitter, params, attachments)
      return if params[:t].present? && params[:t] != SubmissionEvents.build_tracking_param(submitter, 'click_email')
      return if params[:t].blank? && !submitter.submission_events.exists?(event_type: :click_email)

      signature_attachment = find_previous_signature(submitter)

      return if signature_attachment.blank?

      existing_attachment = attachments.find do |a|
        a.blob_id == signature_attachment.blob_id && submitter.id == a.record_id
      end

      return existing_attachment if existing_attachment

      submitter.attachments_attachments.create_or_find_by!(blob_id: signature_attachment.blob_id)
    end

    def find_previous_signature(submitter)
      return if submitter.email.blank?

      submitters_query =
        Submitter.where(email: submitter.email)
                 .where.not(completed_at: nil)
                 .where(SubmissionEvent.where(Submitter.arel_table[:id].eq(SubmissionEvent.arel_table[:submitter_id]))
                                       .where(event_type: :click_email).limit(1).arel.exists)

      ActiveStorage::Attachment.where(name: :signature, record: submitters_query).order(:id).last
    end
  end
end
