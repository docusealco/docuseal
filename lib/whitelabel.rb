# frozen_string_literal: true

# =============================================================================
# Whitelabel — Centralised brand configuration loader
# =============================================================================
# Reads config/whitelabel.yml once at boot and exposes every value through
# simple accessor methods.  All view helpers, mailers, PDF generators and
# other call-sites should use Whitelabel.xxx instead of hard-coding strings.
#
# Usage examples:
#   Whitelabel.brand_name          # => "Intébec"
#   Whitelabel.support_email       # => "support@intebec.ca"
#   Whitelabel.theme(:primary)     # => "216 77% 52%"
#   Whitelabel.email_from          # => "Intébec <info@intebec.ca>"
#   Whitelabel.sign_reason("John") # => "Signed by John with Intébec"
#
# After editing config/whitelabel.yml, call  Whitelabel.reload!  or restart.
# =============================================================================

require 'yaml'

module Whitelabel
  CONFIG_PATH = Rails.root.join('config', 'whitelabel.yml').freeze

  class << self
    # -----------------------------------------------------------------------
    # Core loader
    # -----------------------------------------------------------------------

    def config
      @config ||= load_config
    end

    def reload!
      @config = load_config
    end

    # -----------------------------------------------------------------------
    # Brand identity
    # -----------------------------------------------------------------------

    def brand_name
      config.dig('brand', 'name') || 'DocuSeal'
    end

    def brand_short_name
      config.dig('brand', 'short_name') || brand_name
    end

    def tagline
      config.dig('brand', 'tagline') || ''
    end

    def description
      config.dig('brand', 'description') || ''
    end

    def page_title(signed_in: false)
      key = signed_in ? 'page_title_signed_in' : 'page_title_signed_out'
      config.dig('brand', key) || brand_name
    end

    # -----------------------------------------------------------------------
    # URLs
    # -----------------------------------------------------------------------

    def website_url
      config.dig('urls', 'website') || 'https://intebec.ca'
    end

    def support_email
      config.dig('urls', 'support_email') || 'support@intebec.ca'
    end

    def privacy_policy_url
      config.dig('urls', 'privacy_policy')
    end

    def terms_url
      config.dig('urls', 'terms_of_service')
    end

    def twitter_url
      config.dig('urls', 'twitter_url')
    end

    def twitter_handle
      config.dig('urls', 'twitter_handle')
    end

    def github_url
      config.dig('urls', 'github_url')
    end

    def discord_url
      config.dig('urls', 'discord_url')
    end

    # -----------------------------------------------------------------------
    # Email
    # -----------------------------------------------------------------------

    def email_from
      name = config.dig('email', 'from_name') || brand_name
      addr = config.dig('email', 'from_address') || support_email
      "#{name} <#{addr}>"
    end

    def email_attribution_html
      raw = config.dig('email', 'attribution_html') || ''
      raw.gsub('%{brand}', brand_name).gsub('%{website}', website_url)
    end

    # -----------------------------------------------------------------------
    # Assets
    # -----------------------------------------------------------------------

    def logo_path
      config.dig('assets', 'logo_path') || '/logo.svg'
    end

    def logo_width
      config.dig('assets', 'logo_width') || 37
    end

    def logo_height
      config.dig('assets', 'logo_height') || 37
    end

    def favicon_svg
      config.dig('assets', 'favicon_svg') || '/favicon.svg'
    end

    def favicon_ico
      config.dig('assets', 'favicon_ico') || '/favicon.ico'
    end

    def favicon_16
      config.dig('assets', 'favicon_16') || '/favicon-16x16.png'
    end

    def favicon_32
      config.dig('assets', 'favicon_32') || '/favicon-32x32.png'
    end

    def favicon_96
      config.dig('assets', 'favicon_96') || '/favicon-96x96.png'
    end

    def apple_touch_icon
      config.dig('assets', 'apple_touch_icon') || '/apple-icon-180x180.png'
    end

    def preview_image
      config.dig('assets', 'preview_image') || '/preview.png'
    end

    # -----------------------------------------------------------------------
    # Theme — returns HSL triplets for DaisyUI / CSS custom properties
    # -----------------------------------------------------------------------

    def theme(key)
      config.dig('theme', key.to_s)
    end

    # -----------------------------------------------------------------------
    # PDF / Audit trail
    # -----------------------------------------------------------------------

    def sign_reason(name)
      template = config.dig('pdf', 'sign_reason') || "Signed by %{name} with #{brand_name}"
      template.gsub('%{name}', name.to_s)
    end

    def audit_trail_footer
      config.dig('pdf', 'audit_trail_footer') || "Signed with #{brand_name}"
    end

    def pdf_creator
      creator = config.dig('pdf', 'creator') || brand_name
      "#{creator} (#{website_url})"
    end

    def cert_name
      config.dig('pdf', 'cert_name') || "#{brand_name} Self-Host Autogenerated"
    end

    # -----------------------------------------------------------------------
    # PWA
    # -----------------------------------------------------------------------

    def pwa_description
      config.dig('pwa', 'description') || "#{brand_name} is a secure platform for digital document signing."
    end

    def pwa_theme_color
      config.dig('pwa', 'theme_color') || '#FAF7F4'
    end

    def pwa_background_color
      config.dig('pwa', 'background_color') || '#FAF7F4'
    end

    # -----------------------------------------------------------------------
    # Webhooks
    # -----------------------------------------------------------------------

    def webhook_user_agent
      config.dig('webhooks', 'user_agent') || "#{brand_name} Webhook"
    end

    # -----------------------------------------------------------------------
    # Feature flags
    # -----------------------------------------------------------------------

    def show_github_button?
      config.dig('features', 'show_github_button') == true
    end

    def show_powered_by?
      config.dig('features', 'show_powered_by') != false
    end

    def powered_by_text
      config.dig('features', 'powered_by_text') || brand_name
    end

    def show_ai_link?
      config.dig('features', 'show_ai_link') == true
    end

    def show_discord_link?
      config.dig('features', 'show_discord_link') == true
    end

    def show_pro_upsells?
      config.dig('features', 'show_pro_upsells') == true
    end

    # -----------------------------------------------------------------------
    # Internal / technical
    # -----------------------------------------------------------------------

    def temp_email_domain
      config.dig('internal', 'temp_email_domain') || 'example.com'
    end

    private

    def load_config
      return {} unless CONFIG_PATH.exist?

      YAML.safe_load_file(CONFIG_PATH, permitted_classes: [Symbol]) || {}
    rescue Psych::SyntaxError => e
      Rails.logger.error("[Whitelabel] Failed to parse #{CONFIG_PATH}: #{e.message}")
      {}
    end
  end
end
