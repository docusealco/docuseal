# frozen_string_literal: true

class TemplatesRestoreController < ApplicationController
  def create
    template = current_account.templates.find(params[:template_id])

    template.update!(deleted_at: nil)

    redirect_to template_path(template), notice: 'Template has been unarchived'
  end
end
