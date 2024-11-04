# frozen_string_literal: true

module WebhookUrls
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
end
