# frozen_string_literal: true

module WebhookUrls
  EVENT_TYPE_TO_JOB_CLASS = {
    'form.started' => SendFormStartedWebhookRequestJob,
    'form.completed' => SendFormCompletedWebhookRequestJob,
    'form.declined' => SendFormDeclinedWebhookRequestJob,
    'form.viewed' => SendFormViewedWebhookRequestJob,
    'submission.created' => SendSubmissionCreatedWebhookRequestJob,
    'submission.completed' => SendSubmissionCompletedWebhookRequestJob,
    'submission.expired' => SendSubmissionExpiredWebhookRequestJob,
    'submission.archived' => SendSubmissionArchivedWebhookRequestJob,
    'template.created' => SendTemplateCreatedWebhookRequestJob,
    'template.updated' => SendTemplateUpdatedWebhookRequestJob
  }.freeze

  EVENT_TYPE_ID_KEYS = {
    'form' => 'submitter_id',
    'submission' => 'submission_id',
    'template' => 'template_id'
  }.freeze

  module_function

  def for_account_id(account_id, events)
    events = Array.wrap(events)

    rel = WebhookUrl.where(account_id:)

    event_arel = events.map { |event| Arel::Table.new(:webhook_urls)[:events].matches("%\"#{event}\"%") }.reduce(:or)

    if Docuseal.multitenant? || account_id == 1
      rel.where(event_arel)
    else
      linked_account_rel =
        AccountLinkedAccount.where(linked_account_id: account_id).where.not(account_type: :testing).select(:account_id)

      webhook_urls = rel.or(WebhookUrl.where(account_id: linked_account_rel).where(event_arel))

      account_urls, linked_urls = webhook_urls.partition { |w| w.account_id == account_id }

      account_urls.select { |w| w.events.intersect?(events) }.presence ||
        (account_urls.present? ? WebhookUrl.none : linked_urls)
    end
  end

  def enqueue_events(records, event_type)
    args = []

    id_key = EVENT_TYPE_ID_KEYS.fetch(event_type.split('.').first)

    Array.wrap(records).group_by(&:account_id).each do |account_id, account_records|
      webhook_urls = for_account_id(account_id, event_type)

      account_records.each do |record|
        event_uuid = SecureRandom.uuid

        webhook_urls.each do |webhook_url|
          next unless webhook_url.events.include?(event_type)

          args << [{ id_key => record.id, 'webhook_url_id' => webhook_url.id, 'event_uuid' => event_uuid }]
        end
      end
    end

    Sidekiq::Client.push_bulk('class' => EVENT_TYPE_TO_JOB_CLASS[event_type], 'args' => args)
  end
end
