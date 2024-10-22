# frozen_string_literal: true

class PopulateCompletedSubmittersAndDocuments < ActiveRecord::Migration[7.2]
  disable_ddl_transaction

  class MigrationSubmitter < ApplicationRecord
    self.table_name = 'submitters'

    belongs_to :submission, class_name: 'MigrationSubmission'
    has_many :submission_sms_events, -> { where(event_type: %w[send_sms send_2fa_sms]) },
             class_name: 'MigrationSubmissionEvent', foreign_key: :submitter_id
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
    submitters = MigrationSubmitter.where.not(completed_at: nil)
                                   .preload(:submission, :submission_sms_events)

    count = submitters.count

    puts "Updating the database - it might take ~#{(count / 1000 * 3) + 1} seconds" if count > 2000

    submitters.find_each do |submitter|
      completed_submitter = MigrationCompletedSubmitter.find_or_initialize_by(submitter_id: submitter.id)

      next if completed_submitter.persisted?

      submission = submitter.submission

      completed_submitter.assign_attributes(
        submission_id: submitter.submission_id,
        account_id: submission.account_id,
        template_id: submission.template_id,
        source: submission.source,
        sms_count: submitter.submission_sms_events.size,
        completed_at: submitter.completed_at,
        created_at: submitter.completed_at,
        updated_at: submitter.completed_at
      )

      completed_submitter.save!
    end

    attachments = ActiveStorage::Attachment.where(record_type: 'Submitter', name: 'documents').preload(:blob)

    attachments.find_each do |attachment|
      sha256 = attachment.metadata['sha256']

      next if sha256.blank?

      completed_document = MigrationCompletedDocument.find_or_initialize_by(submitter_id: attachment.record_id, sha256:)

      next if completed_document.persisted?

      completed_document.assign_attributes(created_at: attachment.created_at, updated_at: attachment.created_at)

      completed_document.save!
    end
  end

  def down
    nil
  end
end
