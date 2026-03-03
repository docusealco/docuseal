# frozen_string_literal: true

# =============================================================================
# Whitelabel initializer
# =============================================================================
# Triggers config loading (from local file or Dashboard API) and patches the
# Docuseal module constants so that every existing call to
# Docuseal.product_name, Docuseal::PRODUCT_URL, etc. automatically returns
# the white-labelled value.
# =============================================================================

require_relative '../../lib/whitelabel'

# Ensure lib/docuseal.rb is fully loaded before we reopen and patch the module.
# Without this, Zeitwerk sees `module Docuseal` below and marks the constant as
# already defined, so it never loads lib/docuseal.rb — leaving multitenant? and
# other module_function methods undefined during eager loading.
require Rails.root.join('lib/docuseal')

# Patch Docuseal module to delegate brand-related values to Whitelabel
module Docuseal
  # Override the product_name method to use Whitelabel config
  def self.product_name
    Whitelabel.brand_name
  end

  # Override constants that are used in views/mailers — we make them
  # methods instead so they pick up the Whitelabel config dynamically.
  # The constants still exist for backward compat but the methods take
  # precedence when called as Docuseal.xxx.

  def self.product_url
    Whitelabel.website_url
  end

  def self.support_email_address
    Whitelabel.support_email
  end

  def self.github_url_value
    Whitelabel.github_url || ''
  end

  def self.twitter_url_value
    Whitelabel.twitter_url || ''
  end

  def self.twitter_handle_value
    Whitelabel.twitter_handle || ''
  end

  def self.discord_url_value
    Whitelabel.discord_url || ''
  end
end

Rails.application.config.i18n.default_locale = Whitelabel.default_locale.to_sym
Rails.application.config.i18n.available_locales = Whitelabel.available_locales.map(&:to_sym)
Rails.application.config.i18n.fallbacks = [Whitelabel.fallback_locale.to_sym]

deep_stringify_keys = lambda do |hash|
  hash.each_with_object({}) do |(key, value), memo|
    string_key = key.to_s
    memo[string_key] = value.is_a?(Hash) ? deep_stringify_keys.call(value) : value
  end
end

deep_merge_hash = lambda do |left, right|
  left.merge(right) do |_key, left_value, right_value|
    if left_value.is_a?(Hash) && right_value.is_a?(Hash)
      deep_merge_hash.call(left_value, right_value)
    else
      right_value
    end
  end
end

undot_keys = lambda do |hash|
  hash.each_with_object({}) do |(key, value), memo|
    if key.include?('.')
      head, *tail = key.split('.')
      nested = tail.reverse.reduce(value) { |acc, segment| { segment => acc } }
      memo[head] = memo.key?(head) ? deep_merge_hash.call(memo[head], nested) : nested
    else
      memo[key] = value.is_a?(Hash) ? undot_keys.call(value) : value
    end
  end
end

Whitelabel.translation_overrides.each do |locale, raw_values|
  normalized = undot_keys.call(deep_stringify_keys.call(raw_values))
  I18n.backend.store_translations(locale.to_sym, normalized)
end

Rails.logger.info "[Whitelabel] Loaded brand: #{Whitelabel.brand_name}"
