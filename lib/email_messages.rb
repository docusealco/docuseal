# frozen_string_literal: true

module EmailMessages
  module_function

  def find_or_create_for_account_user(account, user, subject, body)
    subject = I18n.t(:you_are_invited_to_sign_a_document) if subject.blank?

    message = account.email_messages.new(author: user, subject:, body:).tap(&:validate)

    account.email_messages.find_by(sha1: message.sha1) || message.tap { |m| m.save!(validate: false) }
  end
end
