# frozen_string_literal: true

module Submitters
  module SubmitValues
    module_function

    def call(submitter, params, request)
      update_submitter!(submitter, params, request)

      Submissions.update_template_fields!(submitter.submission) if submitter.submission.template_fields.blank?

      submitter.submission.save!

      return unless submitter.completed_at?

      GenerateSubmitterResultAttachmentsJob.perform_later(submitter)

      if submitter.account.encrypted_configs.exists?(key: EncryptedConfig::WEBHOOK_URL_KEY)
        SendWebhookRequestJob.perform_later(submitter)
      end

      submitter.submission.template.account.users.active.each do |user|
        SubmitterMailer.completed_email(submitter, user).deliver_later!
      end

      submitter
    end

    def update_submitter!(submitter, params, request)
      submitter.values.merge!(normalized_values(params))
      submitter.opened_at ||= Time.current

      if params[:completed] == 'true'
        submitter.completed_at = Time.current
        submitter.ip = request.remote_ip
        submitter.ua = request.user_agent
      end

      submitter.save!

      submitter
    end

    def normalized_values(params)
      params.fetch(:values, {}).to_unsafe_h.transform_values do |v|
        if params[:cast_boolean] == 'true'
          v == 'true'
        else
          v.is_a?(Array) ? v.compact_blank : v
        end
      end
    end
  end
end
