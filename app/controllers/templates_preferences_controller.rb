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
                      completed_notification_email_attach_documents
                      completed_redirect_url
                      submitters_order
                      completed_notification_email_subject completed_notification_email_body
                      completed_notification_email_enabled completed_notification_email_attach_audit] +
                      [completed_message: %i[title body]]
    ).tap do |attrs|
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
