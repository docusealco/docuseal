# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  default from: 'DocuSeal <info@docuseal.co>'
  layout 'mailer'

  register_interceptor ActionMailerConfigsInterceptor

  register_observer ActionMailerEventsObserver

  before_action do
    ActiveStorage::Current.url_options = Docuseal.default_url_options
  end

  after_action :set_message_metadata
  after_action :set_message_uuid

  def default_url_options
    Docuseal.default_url_options
  end

  def set_message_metadata
    message.instance_variable_set(:@message_metadata, @message_metadata)
  end

  def set_message_uuid
    message['X-Message-Uuid'] = SecureRandom.uuid
  end

  def assign_message_metadata(tag, record)
    @message_metadata = {
      'tag' => tag,
      'record_id' => record.id,
      'record_type' => record.class.name
    }
  end
end
