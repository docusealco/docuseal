# frozen_string_literal: true

class TemplatesArchivedController < ApplicationController
  load_and_authorize_resource :template, parent: false

  def index
    @templates = @templates.where.not(archived_at: nil).preload(:author, :folder).order(id: :desc)
    @templates = Templates.search(@templates, params[:q])

    @pagy, @templates = pagy(@templates, items: 12)
  end
end
