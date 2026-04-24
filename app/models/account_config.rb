# frozen_string_literal: true

# == Schema Information
#
# Table name: account_configs
#
#  id         :bigint           not null, primary key
#  key        :string           not null
#  value      :text             not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  account_id :bigint           not null
#
# Indexes
#
#  index_account_configs_on_account_id          (account_id)
#  index_account_configs_on_account_id_and_key  (account_id,key) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#
class AccountConfig < ApplicationRecord
  SUBMITTER_INVITATION_EMAIL_KEY = 'submitter_invitation_email'
  SUBMITTER_INVITATION_REMINDER_EMAIL_KEY = 'submitter_invitation_reminder_email'
  SUBMITTER_COMPLETED_EMAIL_KEY = 'submitter_completed_email'
  SUBMITTER_DOCUMENTS_COPY_EMAIL_KEY = 'submitter_documents_copy_email'
  BCC_EMAILS = 'bcc_emails'
  FORCE_MFA = 'force_mfa'
  ALLOW_TYPED_SIGNATURE = 'allow_typed_signature'
  ALLOW_TO_RESUBMIT = 'allow_to_resubmit'
  ALLOW_TO_DECLINE_KEY = 'allow_to_decline'
  ALLOW_TO_DELEGATE_KEY = 'allow_to_delegate'
  ALLOW_TO_PARTIAL_DOWNLOAD_KEY = 'allow_to_partial_download'
  SUBMITTER_REMINDERS = 'submitter_reminders'
  ENFORCE_SIGNING_ORDER_KEY = 'enforce_signing_order'
  FORM_COMPLETED_BUTTON_KEY = 'form_completed_button'
  FORM_COMPLETED_MESSAGE_KEY = 'form_completed_message'
  FORM_WITH_CONFETTI_KEY = 'form_with_confetti'
  FORM_PREFILL_SIGNATURE_KEY = 'form_prefill_signature'
  ESIGNING_PREFERENCE_KEY = 'esigning_preference'
  DOWNLOAD_LINKS_AUTH_KEY = 'download_links_auth'
  DOWNLOAD_LINKS_EXPIRE_KEY = 'download_links_expire'
  FORCE_SSO_AUTH_KEY = 'force_sso_auth'
  FLATTEN_RESULT_PDF_KEY = 'flatten_result_pdf'
  WITH_SIGNATURE_ID = 'with_signature_id'
  WITH_FILE_LINKS_KEY = 'with_file_links'
  WITH_SIGNATURE_ID_REASON_KEY = 'with_signature_id_reason'
  RECIPIENT_FORM_FIELDS_KEY = 'recipient_form_fields'
  WITH_AUDIT_VALUES_KEY = 'with_audit_values'
  WITH_AUDIT_SENDER_KEY = 'with_audit_sender'
  WITH_SUBMITTER_TIMEZONE_KEY = 'with_submitter_timezone'
  WITH_TIMESTAMP_SECONDS_KEY = 'with_timestamp_seconds'
  REQUIRE_SIGNING_REASON_KEY = 'require_signing_reason'
  REUSE_SIGNATURE_KEY = 'reuse_signature'
  WITH_FIELD_LABELS_KEY = 'with_field_labels'
  COMBINE_PDF_RESULT_KEY = 'combine_pdf_result_key'
  DOCUMENT_FILENAME_FORMAT_KEY = 'document_filename_format'
  TEMPLATE_CUSTOM_FIELDS_KEY = 'template_custom_fields'
  POLICY_LINKS_KEY = 'policy_links'
  ENABLE_MCP_KEY = 'enable_mcp'
  EMAIL_FOOTER_MESSAGE_KEY = 'email_footer_message'
  SHOW_CONSOLE_LINK_KEY = 'show_console_link'
  SHOW_API_LINK_KEY = 'show_api_link'
  SHOW_TEST_MODE_KEY = 'show_test_mode'
  BRAND_NAME_KEY = 'brand_name'
  BRAND_NAME_FONT_KEY = 'brand_name_font'

  BRAND_NAME_FONTS = [
    'Inter',
    'system-ui',
    'Dancing Script',
    'Great Vibes',
    'Pacifico',
    'Caveat',
    'Homemade Apple',
    'Mrs Saint Delafield',
    'Shadows Into Light',
    'Alex Brush',
    'Kalam',
    'Sacramento',
    'Herr Von Muellerhoff'
  ].freeze

  SANS_SERIF_BRAND_FONTS = %w[Inter system-ui].freeze

  def self.brand_font_css(font_name)
    return nil unless font_name.present? && BRAND_NAME_FONTS.include?(font_name)

    if SANS_SERIF_BRAND_FONTS.include?(font_name)
      font_name == 'system-ui' ? 'system-ui, sans-serif' : "'#{font_name}', sans-serif"
    else
      "'#{font_name}', cursive"
    end
  end

  EMAIL_VARIABLES = {
    SUBMITTER_INVITATION_EMAIL_KEY => %w[template.name submitter.link account.name].freeze,
    SUBMITTER_COMPLETED_EMAIL_KEY => %w[template.name submission.submitters submission.link].freeze,
    SUBMITTER_INVITATION_REMINDER_EMAIL_KEY => %w[template.name submitter.link account.name].freeze,
    SUBMITTER_DOCUMENTS_COPY_EMAIL_KEY => %w[template.name documents.link account.name].freeze
  }.freeze

  DEFAULT_VALUES = {
    SUBMITTER_INVITATION_EMAIL_KEY => lambda {
      {
        'subject' => I18n.t(:you_are_invited_to_sign_a_document),
        'body' => I18n.t(:submitter_invitation_email_sign_body)
      }
    },
    SUBMITTER_INVITATION_REMINDER_EMAIL_KEY => lambda {
      {
        'subject' => I18n.t(:you_are_invited_to_sign_a_document),
        'body' => I18n.t(:submitter_invitation_email_sign_body)
      }
    },
    SUBMITTER_COMPLETED_EMAIL_KEY => lambda {
      {
        'subject' => I18n.t(:template_name_has_been_completed_by_submitters),
        'body' => I18n.t(:submitter_completed_email_body)
      }
    },
    SUBMITTER_DOCUMENTS_COPY_EMAIL_KEY => lambda {
      {
        'subject' => I18n.t(:your_document_copy),
        'body' => I18n.t(:submitter_documents_copy_email_body)
      }
    }
  }.freeze

  ENV_PREFIX = 'DOCUSEAL_CONFIG_'

  BOOLEAN_ENV_VALUES = {
    'true' => true, '1' => true, 'yes' => true, 'on' => true,
    'false' => false, '0' => false, 'no' => false, 'off' => false
  }.freeze

  belongs_to :account

  serialize :value, coder: JSON

  # Returns the ENV variable name for a given account_config key.
  # Example: env_key_for('allow_typed_signature') => 'DOCUSEAL_CONFIG_ALLOW_TYPED_SIGNATURE'
  def self.env_key_for(key)
    "#{ENV_PREFIX}#{key.to_s.upcase}"
  end

  # Returns the raw ENV value for a key (or nil if not set).
  def self.env_override(key)
    ENV.fetch(env_key_for(key), nil)
  end

  # True when the corresponding ENV variable is set (non-nil, non-empty).
  def self.locked_by_env?(key)
    ENV.fetch(env_key_for(key), nil).present?
  end

  # Parses the ENV override for a given key:
  # - boolean-ish strings -> true/false
  # - valid JSON -> parsed structure
  # - otherwise -> raw string
  def self.env_override_cast(key)
    raw = env_override(key)
    return nil if raw.nil?

    downcased = raw.downcase
    return BOOLEAN_ENV_VALUES[downcased] if BOOLEAN_ENV_VALUES.key?(downcased)

    begin
      JSON.parse(raw)
    rescue JSON::ParserError
      raw
    end
  end
end
