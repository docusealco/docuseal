# frozen_string_literal: true

class ProcessSubmitterCompletionJob
  include Sidekiq::Job

  def perform(params = {})
    submitter = Submitter.find(params['submitter_id'])

    create_completed_submitter!(submitter)

    is_all_completed = !submitter.submission.submitters.exists?(completed_at: nil)

    Submissions::EnsureResultGenerated.call(submitter)

    if is_all_completed && submitter.completed_at == submitter.submission.submitters.maximum(:completed_at)
      if submitter.submission.account.account_configs.exists?(key: AccountConfig::COMBINE_PDF_RESULT_KEY, value: true)
        Submissions::GenerateCombinedAttachment.call(submitter)
      end

      maybe_regenerate_audit_trail(submitter)

      enqueue_completed_emails(submitter)
    end

    create_completed_documents!(submitter)

    if !is_all_completed && submitter.submission.signing_order_enforced? && params['send_invitation_email'] != false
      enqueue_next_submitter_request_notification(submitter)
    end

    enqueue_completed_webhooks(submitter, is_all_completed:)
  end

  def create_completed_submitter!(submitter)
    completed_submitter = CompletedSubmitter.find_or_initialize_by(submitter_id: submitter.id)

    return completed_submitter if completed_submitter.persisted?

    submission = submitter.submission

    completed_submitter.assign_attributes(
      submission_id: submitter.submission_id,
      account_id: submission.account_id,
      template_id: submission.template_id,
      source: submission.source,
      sms_count: submitter.submission_events.where(event_type: %w[send_sms send_2fa_sms]).count,
      completed_at: submitter.completed_at
    )

    completed_submitter.save!

    completed_submitter
  rescue ActiveRecord::RecordNotUnique
    retry
  end

  def create_completed_documents!(submitter)
    submitter.documents.filter_map do |attachment|
      next if attachment.metadata['sha256'].blank?

      # Determine storage location based on service used
      storage_location = determine_storage_location_for_attachment(attachment)

      CompletedDocument.find_or_create_by!(sha256: attachment.metadata['sha256'], submitter_id: submitter.id) do |doc|
        doc.storage_location = storage_location
      end
    end
  end

  def determine_storage_location_for_attachment(attachment)
    # Check if attachment is stored in secured storage
    service_name = attachment.blob.service_name
    service_name == 'aws_s3_secured' ? 'secured' : 'legacy'
  end

  def enqueue_completed_webhooks(submitter, is_all_completed: false)
    WebhookUrls.for_account_id(submitter.account_id, %w[form.completed submission.completed]).each do |webhook|
      if webhook.events.include?('form.completed')
        SendFormCompletedWebhookRequestJob.perform_async('submitter_id' => submitter.id,
                                                         'webhook_url_id' => webhook.id)
      end

      if webhook.events.include?('submission.completed') && is_all_completed
        SendSubmissionCompletedWebhookRequestJob.perform_async('submission_id' => submitter.submission_id,
                                                               'webhook_url_id' => webhook.id)
      end
    end
  end

  def enqueue_completed_emails(submitter)
    submission = submitter.submission

    user = submission.created_by_user || submitter.template.author

    if submitter.account.users.exists?(id: user.id) && submission.preferences['send_email'] != false &&
       submitter.template&.preferences&.dig('completed_notification_email_enabled') != false
      if submission.submitters.map(&:email).exclude?(user.email) &&
         user.user_configs.find_by(key: UserConfig::RECEIVE_COMPLETED_EMAIL)&.value != false &&
         user.role != 'integration'
        SubmitterMailer.completed_email(submitter, user).deliver_later!
      end

      build_bcc_addresses(submission).each do |to|
        SubmitterMailer.completed_email(submitter, user, to:).deliver_later!
      end
    end

    maybe_enqueue_copy_emails(submitter)
  end

  def maybe_enqueue_copy_emails(submitter)
    return if submitter.template&.preferences&.dig('documents_copy_email_enabled') == false

    configs = AccountConfigs.find_or_initialize_for_key(submitter.account,
                                                        AccountConfig::SUBMITTER_DOCUMENTS_COPY_EMAIL_KEY)

    return if configs.value['enabled'] == false

    to = submitter.submission.submitters.reject { |e| e.preferences['send_email'] == false }
                  .sort_by(&:completed_at).select(&:email?).map(&:friendly_name)

    return if to.blank?

    if configs.value['bcc_recipients'] == true
      to.each { |to| SubmitterMailer.documents_copy_email(submitter, to:).deliver_later! }
    else
      SubmitterMailer.documents_copy_email(submitter, to: to.join(', ')).deliver_later!
    end
  end

  def build_bcc_addresses(submission)
    bcc = submission.preferences['bcc_completed'].presence ||
          submission.template&.preferences&.dig('bcc_completed').presence ||
          submission.account.account_configs
                    .find_by(key: AccountConfig::BCC_EMAILS)&.value

    bcc.to_s.scan(User::EMAIL_REGEXP)
  end

  def enqueue_next_submitter_request_notification(submitter)
    next_submitter_item =
      submitter.submission.template_submitters.find do |e|
        sub = submitter.submission.submitters.find { |s| s.uuid == e['uuid'] }

        next unless sub

        sub.completed_at.blank? && sub.sent_at.blank?
      end

    return unless next_submitter_item

    next_submitter = submitter.submission.submitters.find { |s| s.uuid == next_submitter_item['uuid'] }

    Submitters.send_signature_requests([next_submitter])
  end

  def maybe_regenerate_audit_trail(submitter)
    # Regenerate audit trail if it doesn't exist or was created before latest completion
    # This handles re-completion after change requests
    latest_completion = submitter.submission.submitters.maximum(:completed_at)
    existing_audit_trail = ActiveStorage::Attachment.find_by(
      record: submitter.submission,
      name: 'audit_trail'
    )

    should_regenerate = existing_audit_trail.blank? ||
                        existing_audit_trail.created_at < latest_completion

    return unless should_regenerate

    # Generate new audit trail first (safer - keeps old one if generation fails)
    Submissions::GenerateAuditTrail.call(submitter.submission)

    # Clean up old audit trail attachments, keeping only the newest
    # This handles multiple PDFs created during re-completion after change requests
    audit_trail_attachments = ActiveStorage::Attachment.where(
      record: submitter.submission,
      name: 'audit_trail'
    ).order(created_at: :asc)

    # Keep only the newest, purge the rest
    return unless audit_trail_attachments.count > 1

    audit_trail_attachments.limit(audit_trail_attachments.count - 1).each(&:purge)
  end
end
