# frozen_string_literal: true

locale = ENV.fetch('DIELCA_LOCALE', 'es-ES')
Rails.application.config.i18n.default_locale = locale.to_sym

Rails.application.config.to_prepare do
  Account.attribute :locale, :string, default: locale
end
