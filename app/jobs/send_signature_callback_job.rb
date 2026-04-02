# frozen_string_literal: true

class SendSignatureCallbackJob
  include Sidekiq::Job

  sidekiq_options queue: :webhooks

  TRACKED_FIELD_NAMES = %w[provider_signature client_caregiver_signature supervisor_signature].freeze
  CALLBACK_ENDPOINT = 'https://app.therapypms.com/v1/note/signed'.freeze

  def perform(params = {})
    submitter = Submitter.find_by(id: params['submitter_id'])

    return unless submitter&.completed_at?

    callback_url = AccountConfig.find_by(
      account_id: submitter.account_id,
      key: AccountConfig::SIGNATURE_CALLBACK_URL_KEY
    )&.value.presence || CALLBACK_ENDPOINT

    fields = submitter.submission.template_fields || submitter.submission.template&.fields

    return unless fields

    tracked_fields = fields.select do |f|
      f['submitter_uuid'] == submitter.uuid &&
        f['type'] == 'signature' &&
        TRACKED_FIELD_NAMES.include?(f['name'])
    end

    return if tracked_fields.empty?

    attachments_index = submitter.attachments.preload(:blob).index_by(&:uuid)

    signatures = tracked_fields.filter_map do |field|
      attachment_uuid = submitter.values[field['uuid']]
      next unless attachment_uuid.present?

      attachment = attachments_index[attachment_uuid]
      next unless attachment

      {
        field_name: field['name'],
        field_uuid: field['uuid'],
        signature: Base64.strict_encode64(attachment.download)
      }
    end

    return if signatures.empty?

    payload = {
      admin_id: submitter.submission.created_by_user_id,
      template_id: submitter.submission.template_id,
      submission_id: submitter.submission_id,
      embed_src: build_embed_src(submitter),
      email: submitter.email,
      signatures: signatures
    }

    Faraday.post(callback_url) do |req|
      req.headers['Content-Type'] = 'application/json'
      req.body = payload.to_json
      req.options.read_timeout = 10
      req.options.open_timeout = 10
    end
  rescue Faraday::Error => e
    Rails.logger.error("SendSignatureCallbackJob error for submitter #{params['submitter_id']}: #{e.message}")
  end

  private

  def build_embed_src(submitter)
    opts = Docuseal.default_url_options
    port = opts[:port] ? ":#{opts[:port]}" : ''

    "#{opts[:protocol]}://#{opts[:host]}#{port}/submissions/#{submitter.submission_id}"
  end
end
