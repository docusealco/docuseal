# frozen_string_literal: true

class SendFormDeclinedWebhookRequestJob
  include WebhookRequestJob

  def perform(params = {})
    perform_webhook_request(params, record_key: 'submitter_id', record_class: Submitter,
                                    event_type: 'form.declined') do |submitter|
      ActiveStorage::Current.url_options = Docuseal.default_url_options
      Submitters::SerializeForWebhook.call(submitter)
    end
  end
end
