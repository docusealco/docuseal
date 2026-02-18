# frozen_string_literal: true

module WebhookUrls
  module_function

  def for_template(template, events)
    if template.partnership_id.present?
      for_partnership_id(template.partnership_id, events)
    elsif template.account_id.present?
      for_account_id(template.account_id, events)
    else
      raise ArgumentError, 'Template must have either account_id or partnership_id'
    end
  end

  def for_account_id(account_id, events)
    rel = WebhookUrl.where(account_id:)

    if Docuseal.multitenant? || account_id == 1
      rel.where(event_matcher(events))
    else
      linked_account_rel =
        AccountLinkedAccount.where(linked_account_id: account_id).where.not(account_type: :testing).select(:account_id)

      webhook_urls = rel.or(WebhookUrl.where(account_id: linked_account_rel).where(event_matcher(events)))

      account_urls, linked_urls = webhook_urls.partition { |w| w.account_id == account_id }

      account_urls.select { |w| w.events.intersect?(Array.wrap(events)) }.presence ||
        (account_urls.present? ? WebhookUrl.none : linked_urls)
    end
  end

  def for_partnership_id(partnership_id, events)
    WebhookUrl.where(partnership_id:).where(event_matcher(events))
  end

  def event_matcher(events)
    events = Array.wrap(events)

    # Validate against known events constant
    invalid_events = events - WebhookUrl::EVENTS
    raise ArgumentError, "Invalid events: #{invalid_events.join(', ')}" if invalid_events.any?

    conditions = events.map { 'events LIKE ?' }.join(' OR ')
    values = events.map { |event| "%\"#{event}\"%" }
    [conditions, *values]
  end
end
