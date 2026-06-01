# frozen_string_literal: true

module CanCan
  module UnauthorizedMessageResolver
    def unauthorized_message(action, subject)
      subject = subject.values.last if subject.is_a?(Hash)
      keys = unauthorized_message_keys(action, subject)
      variables = {}
      variables[:action] = I18n.translate("actions.#{action}", default: action.to_s)
      variables[:subject] = translate_subject(subject)
      message = I18n.translate(keys.shift, **variables.merge(scope: :unauthorized, default: keys + ['']))
      message.blank? ? nil : message
    end

    def translate_subject(subject)
      klass = (subject.class == Class ? subject : subject.class)
      if klass.respond_to?(:model_name)
        klass.model_name.human
      else
        klass.to_s.underscore.humanize.downcase
      end
    end
  end
end
