# frozen_string_literal: true

class ProcessSubmitterCompletionJob
  include Sidekiq::Job

  def perform(params = {})
    submitter = Submitter.find(params['submitter_id'])

    is_all_completed = !submitter.submission.submitters.exists?(completed_at: nil)

    if !is_all_completed && submitter.submission.submitters_order_preserved?
      enqueue_next_submitter_request_notification(submitter)
    end

    Submissions::EnsureResultGenerated.call(submitter)

    if is_all_completed && submitter.completed_at == submitter.submission.submitters.maximum(:completed_at)
      Submissions::GenerateAuditTrail.call(submitter.submission)

      enqueue_completed_emails(submitter)
    end

    enqueue_completed_webhooks(submitter)
  end

  def enqueue_completed_webhooks(submitter)
    webhook_config = Accounts.load_webhook_config(submitter.account)

    if webhook_config
      SendFormCompletedWebhookRequestJob.perform_async({ 'submitter_id' => submitter.id,
                                                         'encrypted_config_id' => webhook_config.id })
    end

    webhook_ids = submitter.account.webhook_urls.where(
      Arel::Table.new(:webhook_urls)[:events].matches('%"form.completed"%')
    ).pluck(:id)

    webhook_ids.each do |webhook_id|
      SendFormCompletedWebhookRequestJob.perform_async({ 'submitter_id' => submitter.id,
                                                         'webhook_url_id' => webhook_id })
    end
  end

  def enqueue_completed_emails(submitter)
    submission = submitter.submission

    user = submission.created_by_user || submitter.template.author

    if submitter.account.users.exists?(id: user.id) && submission.preferences['send_email'] != false &&
       submitter.template.preferences['completed_notification_email_enabled'] != false
      if submission.submitters.map(&:email).exclude?(user.email) &&
         user.user_configs.find_by(key: UserConfig::RECEIVE_COMPLETED_EMAIL)&.value != false &&
         user.role != 'integration'
        SubmitterMailer.completed_email(submitter, user).deliver_later!
      end

      build_bcc_addresses(submission).each do |to|
        SubmitterMailer.completed_email(submitter, user, to:).deliver_later!
      end
    end

    to = build_to_addresses(submitter)

    return if to.blank? || submitter.template.preferences['documents_copy_email_enabled'] == false

    SubmitterMailer.documents_copy_email(submitter, to:).deliver_later!
  end

  def build_bcc_addresses(submission)
    bcc = submission.preferences['bcc_completed'].presence ||
          submission.template.preferences['bcc_completed'].presence ||
          submission.account.account_configs
                    .find_by(key: AccountConfig::BCC_EMAILS)&.value

    bcc.to_s.scan(User::EMAIL_REGEXP)
  end

  def build_to_addresses(submitter)
    submitter.submission.submitters.reject { |e| e.preferences['send_email'] == false }
             .sort_by(&:completed_at).select(&:email?).map(&:friendly_name).join(', ')
  end

  def enqueue_next_submitter_request_notification(submitter)
    next_submitter_item =
      submitter.submission.template_submitters.find do |e|
        sub = submitter.submission.submitters.find { |s| s.uuid == e['uuid'] }

        sub.completed_at.blank? && sub.sent_at.blank?
      end

    return unless next_submitter_item

    next_submitter = submitter.submission.submitters.find { |s| s.uuid == next_submitter_item['uuid'] }

    Submitters.send_signature_requests([next_submitter])
  end
end
