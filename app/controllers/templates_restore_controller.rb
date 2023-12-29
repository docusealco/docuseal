# frozen_string_literal: true

class TemplatesRestoreController < ApplicationController
  load_and_authorize_resource :template

  def create
    @template.update!(archived_at: nil)

    redirect_to template_path(@template), notice: 'Template has been unarchived'
  end
end
