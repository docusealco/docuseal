# frozen_string_literal: true

Rails.application.config.i18n.default_locale = :es

Rails.application.config.to_prepare do
  Account.attribute :locale, :string, default: 'es'
end
