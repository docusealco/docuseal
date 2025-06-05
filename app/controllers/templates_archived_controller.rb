# frozen_string_literal: true

class TemplatesArchivedController < ApplicationController
  load_and_authorize_resource :template, parent: false

  def index
    @templates = @templates.where.not(archived_at: nil).preload(:author, :folder, :template_accesses).order(id: :desc)
    @templates = Templates.search(current_user, @templates, params[:q])

    @pagy, @templates = pagy_auto(@templates, limit: 12)
  end
end
