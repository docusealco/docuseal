# frozen_string_literal: true

module ActionMailerEventsObserver
  module_function

  def delivered_email(mail)
    data = mail.instance_variable_get(:@message_metadata)

    return if data.blank?

    tag, emailable_id, emailable_type = data.values_at('tag', 'record_id', 'record_type')

    return if tag.blank? || emailable_type.blank? || emailable_id.blank?

    message_id = fetch_message_id(mail)

    all_emails(mail).each do |email|
      EmailEvent.create!(
        tag:,
        message_id:,
        emailable_id:,
        emailable_type:,
        event_type: :send,
        email:,
        data: { method: mail.delivery_method.class.name.underscore },
        event_datetime: Time.current
      )
    end
  rescue StandardError => e
    Rollbar.error(e) if defined?(Rollbar)

    raise if Rails.env.local?
  end

  def fetch_message_id(mail)
    mail['X-Message-Uuid']&.value || SecureRandom.uuid
  end

  def all_emails(mail)
    mail.to.to_a + mail.cc.to_a + mail.bcc.to_a
  end
end
