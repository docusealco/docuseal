# frozen_string_literal: true

class TemplatesPreferencesController < ApplicationController
  load_and_authorize_resource :template

  def show; end

  def create
    authorize!(:update, @template)

    @template.preferences = @template.preferences.merge(template_params[:preferences])
    @template.save!

    head :ok
  end

  private

  def template_params
    params.require(:template).permit(
      preferences: %i[bcc_completed request_email_subject request_email_body
                      documents_copy_email_subject documents_copy_email_body]
    )
  end
end
