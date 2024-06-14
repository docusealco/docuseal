# frozen_string_literal: true

class TemplatesPreferencesController < ApplicationController
  load_and_authorize_resource :template

  def show; end

  def create
    authorize!(:update, @template)

    @template.preferences = @template.preferences.merge(template_params[:preferences])
    @template.preferences = @template.preferences.reject { |_, v| v.is_a?(String) && v.blank? }
    @template.save!

    head :ok
  end

  private

  def template_params
    params.require(:template).permit(
      preferences: %i[bcc_completed request_email_subject request_email_body
                      documents_copy_email_subject documents_copy_email_body
                      documents_copy_email_enabled]
    ).tap do |attrs|
      attrs[:preferences] = attrs[:preferences].transform_values do |value|
        if %w[true false].include?(value)
          value == 'true'
        else
          value
        end
      end
    end
  end
end
