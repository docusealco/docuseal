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
  SUBMITTER_REMINDERS = 'submitter_reminders'
  FORM_COMPLETED_BUTTON_KEY = 'form_completed_button'
  FORM_COMPLETED_MESSAGE_KEY = 'form_completed_message'
  FORM_WITH_CONFETTI_KEY = 'form_with_confetti'
  FORM_PREFILL_SIGNATURE_KEY = 'form_prefill_signature'
  ESIGNING_PREFERENCE_KEY = 'esigning_preference'
  WEBHOOK_PREFERENCES_KEY = 'webhook_preferences'
  DOWNLOAD_LINKS_AUTH_KEY = 'download_links_auth'
  FORCE_SSO_AUTH_KEY = 'force_sso_auth'
  FLATTEN_RESULT_PDF_KEY = 'flatten_result_pdf'
  WITH_SIGNATURE_ID = 'with_signature_id'

  DEFAULT_VALUES = {
    SUBMITTER_INVITATION_EMAIL_KEY => {
      'subject' => 'You are invited to submit a form',
      'body' => "Hi there,\n\n" \
                "You have been invited to submit the \"{{template.name}}\" form.\n\n" \
                "{{submitter.link}}\n\n" \
                "Please contact us by replying to this email if you didn't request this.\n\n" \
                "Thanks,\n" \
                '{{account.name}}'
    },
    SUBMITTER_COMPLETED_EMAIL_KEY => {
      'subject' => '{{template.name}} has been completed by {{submission.submitters}}',
      'body' => "Hi,\n\n" \
                "\"{{template.name}}\" form has been completed by {{submission.submitters}}\n\n" \
                '{{submission.link}}'
    },
    SUBMITTER_DOCUMENTS_COPY_EMAIL_KEY => {
      'subject' => 'Your document copy',
      'body' => "Hi there,\n\n" \
                "Please check the copy of your \"{{template.name}}\" submission in the email attachments.\n" \
                "Alternatively, you can download your copy using:\n\n" \
                "{{documents.link}}\n\n" \
                "Thanks,\n" \
                '{{account.name}}'
    }
  }.freeze

  belongs_to :account

  serialize :value, coder: JSON
end
