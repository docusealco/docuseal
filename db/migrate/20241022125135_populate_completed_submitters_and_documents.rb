# frozen_string_literal: true

class PopulateCompletedSubmittersAndDocuments < ActiveRecord::Migration[7.2]
  disable_ddl_transaction

  class MigrationSubmitter < ApplicationRecord
    self.table_name = 'submitters'

    belongs_to :submission, class_name: 'MigrationSubmission'
    has_many :submission_events, class_name: 'MigrationSubmissionEvent', foreign_key: :submitter_id
  end

  class MigrationSubmission < ApplicationRecord
    self.table_name = 'submissions'
  end

  class MigrationSubmissionEvent < ApplicationRecord
    self.table_name = 'submission_events'
  end

  class MigrationCompletedSubmitter < ApplicationRecord
    self.table_name = 'completed_submitters'
  end

  class MigrationCompletedDocument < ApplicationRecord
    self.table_name = 'completed_documents'
  end

  def up
    completed_submitters = MigrationSubmitter.where.not(completed_at: nil)

    completed_submitters.order(created_at: :asc).preload(:submission).find_each do |submitter|
      submission = submitter.submission
      sms_count = submitter.submission_events.where(event_type: %w[send_sms send_2fa_sms]).count
      completed_submitter = MigrationCompletedSubmitter.where(submitter_id: submitter.id).first_or_initialize
      completed_submitter.assign_attributes(
        submission_id: submitter.submission_id,
        account_id: submission.account_id,
        template_id: submission.template_id,
        source: submission.source,
        sms_count:,
        completed_at: submitter.completed_at,
        created_at: submitter.completed_at,
        updated_at: submitter.completed_at
      )

      completed_submitter.save!
    end

    ActiveStorage::Attachment.where(record_id: completed_submitters.select(:id),
                                    record_type: 'Submitter',
                                    name: 'documents')
                             .order(created_at: :asc)
                             .find_each do |attachment|
      sha256 = attachment.metadata['sha256']
      submitter_id = attachment.record_id

      next if sha256.blank?

      completed_document = MigrationCompletedDocument.where(submitter_id:, sha256:).first_or_initialize
      completed_document.assign_attributes(
        created_at: attachment.created_at,
        updated_at: attachment.created_at
      )

      completed_document.save!
    end
  end

  def down
    nil
  end
end
