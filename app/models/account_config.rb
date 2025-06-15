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
  SUBMITTER_COMPLETED_EMAIL_KEY = 'submitter_completed_email'
  SUBMITTER_DOCUMENTS_COPY_EMAIL_KEY = 'submitter_documents_copy_email'
  BCC_EMAILS = 'bcc_emails'
  FORCE_MFA = 'force_mfa'
  ALLOW_TYPED_SIGNATURE = 'allow_typed_signature'
  ALLOW_TO_RESUBMIT = 'allow_to_resubmit'
  ALLOW_TO_DECLINE_KEY = 'allow_to_decline'
  ALLOW_TO_PARTIAL_DOWNLOAD_KEY = 'allow_to_partial_download'
  SUBMITTER_REMINDERS = 'submitter_reminders'
  ENFORCE_SIGNING_ORDER_KEY = 'enforce_signing_order'
  FORM_COMPLETED_BUTTON_KEY = 'form_completed_button'
  FORM_COMPLETED_MESSAGE_KEY = 'form_completed_message'
  FORM_WITH_CONFETTI_KEY = 'form_with_confetti'
  FORM_PREFILL_SIGNATURE_KEY = 'form_prefill_signature'
  ESIGNING_PREFERENCE_KEY = 'esigning_preference'
  DOWNLOAD_LINKS_AUTH_KEY = 'download_links_auth'
  FORCE_SSO_AUTH_KEY = 'force_sso_auth'
  FLATTEN_RESULT_PDF_KEY = 'flatten_result_pdf'
  WITH_SIGNATURE_ID = 'with_signature_id'
  WITH_AUDIT_VALUES_KEY = 'with_audit_values'
  WITH_AUDIT_SUBMITTER_TIMEZONE_KEY = 'with_audit_submitter_timezone'
  REQUIRE_SIGNING_REASON_KEY = 'require_signing_reason'
  REUSE_SIGNATURE_KEY = 'reuse_signature'
  COMBINE_PDF_RESULT_KEY = 'combine_pdf_result_key'
  DOCUMENT_FILENAME_FORMAT_KEY = 'document_filename_format'
  POLICY_LINKS_KEY = 'policy_links'

  DEFAULT_VALUES = {
    SUBMITTER_INVITATION_EMAIL_KEY => lambda {
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

  belongs_to :account

  serialize :value, coder: JSON
end
