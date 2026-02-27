# frozen_string_literal: true

# =============================================================================
# Whitelabel initializer
# =============================================================================
# Loads config/whitelabel.yml and patches the Docuseal module constants so that
# every existing call to Docuseal.product_name, Docuseal::PRODUCT_URL, etc.
# automatically returns the white-labelled value.
#
# This approach means we do NOT have to change every single call-site — the
# existing code keeps working, but returns branded values.
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

Rails.logger.info "[Whitelabel] Loaded brand: #{Whitelabel.brand_name}"
