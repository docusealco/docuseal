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
        Submissions::EnsureCombinedGenerated.call(submitter)
      end

      Submissions::EnsureAuditGenerated.call(submitter.submission)

      enqueue_completed_emails(submitter)
    end

    create_completed_documents!(submitter)

    if !is_all_completed && submitter.submission.submitters_order_preserved? && params['send_invitation_email'] != false
      enqueue_next_submitter_request_notification(submitter)
    end

    enqueue_completed_webhooks(submitter, is_all_completed:)
  end

  def create_completed_submitter!(submitter)
    completed_submitter = CompletedSubmitter.find_or_initialize_by(submitter_id: submitter.id)

    return completed_submitter if completed_submitter.persisted?

    submission = submitter.submission

    complete_verification_events, sms_events =
      submitter.submission_events.where(event_type: %i[send_sms send_2fa_sms complete_verification])
               .partition { |e| e.event_type == 'complete_verification' }

    complete_verification_event = complete_verification_events.first

    completed_submitter.assign_attributes(
      submission_id: submitter.submission_id,
      account_id: submission.account_id,
      is_first: !CompletedSubmitter.exists?(submission: submitter.submission_id, is_first: true),
      template_id: submission.template_id,
      source: submission.source,
      sms_count: sms_events.sum { |e| e.data['segments'] || 1 },
      verification_method: complete_verification_event&.data&.dig('method'),
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

      CompletedDocument.find_or_create_by!(sha256: attachment.metadata['sha256'], submitter_id: submitter.id)
    end
  end

  def enqueue_completed_webhooks(submitter, is_all_completed: false)
    event_uuids = {}

    WebhookUrls.for_account_id(submitter.account_id, %w[form.completed submission.completed]).each do |webhook|
      if webhook.events.include?('form.completed')
        event_uuids['form.completed'] ||= SecureRandom.uuid

        SendFormCompletedWebhookRequestJob.perform_async('submitter_id' => submitter.id,
                                                         'event_uuid' => event_uuids['form.completed'],
                                                         'webhook_url_id' => webhook.id)
      end

      next unless webhook.events.include?('submission.completed') && is_all_completed

      event_uuids['submission.completed'] ||= SecureRandom.uuid

      SendSubmissionCompletedWebhookRequestJob.perform_async('submission_id' => submitter.submission_id,
                                                             'event_uuid' => event_uuids['submission.completed'],
                                                             'webhook_url_id' => webhook.id)
    end
  end

  def enqueue_completed_emails(submitter)
    submission = submitter.submission
    template = submitter.template

    user = submission.created_by_user || template.author

    if submitter.account.users.exists?(id: user.id) && submission.preferences['send_email'] != false &&
       (!template || template.preferences['completed_notification_email_enabled'] != false)
      user_submitter = submission.submitters.find { |s| s.email == user.email }

      is_sent_to_user =
        if user.role != 'integration' &&
           (!user_submitter || user_submitter.preferences['send_email'] == false) &&
           user.user_configs.find_by(key: UserConfig::RECEIVE_COMPLETED_EMAIL)&.value != false
          SubmitterMailer.completed_email(submitter, user).deliver_later!

          true
        end

      build_bcc_addresses(submission).each do |to|
        next if is_sent_to_user && to == user.email

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
    submission = submitter.submission
    submitters_index = submission.submitters.index_by(&:uuid)

    next_submitter_items =
      if submission.template_submitters.any? { |s| s['order'] }
        submitter_groups =
          submission.template_submitters.group_by.with_index { |s, index| s['order'] || index }

        current_group_index = submitter_groups.find { |_, group| group.any? { |s| s['uuid'] == submitter.uuid } }&.first

        if submitter_groups[current_group_index + 1] &&
           submitters_index.values_at(*submitter_groups[current_group_index].pluck('uuid'))
                           .compact.all?(&:completed_at?)
          submitter_groups[current_group_index + 1]
        end
      else
        submission.template_submitters.find do |e|
          sub = submitters_index[e['uuid']]

          next unless sub

          sub.completed_at.blank? && sub.sent_at.blank?
        end
      end

    next_submitters = submitters_index.values_at(*Array.wrap(next_submitter_items).pluck('uuid')).compact

    Submitters.send_signature_requests(next_submitters)
  end
end
