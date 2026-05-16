# frozen_string_literal: true

class SendSubmitterInvitationSmsJob
  include Sidekiq::Job

  sidekiq_options retry: 5

  def perform(params = {})
    submitter = Submitter.find(params['submitter_id'])

    return if submitter.completed_at?
    return if submitter.submission.archived_at?
    return if submitter.template&.archived_at?
    return if submitter.phone.blank?
    return unless Sms.enabled_for?(submitter.account)

    text = build_body(submitter)

    Sms.send_message(account: submitter.account, to: submitter.phone, text: text)

    SubmissionEvent.create!(submitter: submitter, event_type: 'send_sms')

    submitter.sent_at ||= Time.current
    submitter.save!
  end

  private

  def build_body(submitter)
    account_template = AccountConfig.find_by(account_id: submitter.account_id,
                                             key: AccountConfig::SUBMITTER_INVITATION_SMS_KEY)
    template = account_template&.value.presence ||
               I18n.t('submitter_invitation_sms_body_sign',
                      locale: submitter.account.locale,
                      default: '{account.name} has invited you to sign a document: {submitter.link}')

    ReplaceEmailVariables.call(template, submitter: submitter, tracking_event_type: 'click_sms')
  end
end
