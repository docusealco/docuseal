# frozen_string_literal: true

class TemplatesPreferencesController < ApplicationController
  load_and_authorize_resource :template

  def show; end

  def create
    authorize!(:update, @template)

    @template.preferences = @template.preferences.merge(template_params[:preferences])
    @template.preferences = @template.preferences.reject { |_, v| (v.is_a?(String) || v.is_a?(Hash)) && v.blank? }
    @template.save!

    head :ok
  end

  private

  def template_params
    params.require(:template).permit(
      preferences: %i[bcc_completed request_email_subject request_email_body
                      documents_copy_email_subject documents_copy_email_body
                      documents_copy_email_enabled documents_copy_email_attach_audit
                      documents_copy_email_attach_documents documents_copy_email_reply_to
                      completed_notification_email_attach_documents
                      completed_redirect_url validate_unique_submitters
                      require_all_submitters submitters_order require_phone_2fa
                      default_expire_at_duration
                      default_expire_at
                      completed_notification_email_subject completed_notification_email_body
                      completed_notification_email_enabled completed_notification_email_attach_audit] +
                      [completed_message: %i[title body],
                       submitters: [%i[uuid request_email_subject request_email_body]], link_form_fields: []]
    ).tap do |attrs|
      attrs[:preferences].delete(:submitters) if params[:request_email_per_submitter] != '1'

      if (default_expire_at = attrs.dig(:preferences, :default_expire_at).presence)
        attrs[:preferences][:default_expire_at] =
          (ActiveSupport::TimeZone[current_account.timezone] || Time.zone).parse(default_expire_at).utc
      end

      attrs[:preferences] = attrs[:preferences].transform_values do |value|
        if %w[true false].include?(value)
          value == 'true'
        elsif value.respond_to?(:compact_blank)
          value.compact_blank
        else
          value
        end
      end
    end
  end
end
