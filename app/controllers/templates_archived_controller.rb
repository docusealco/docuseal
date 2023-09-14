# frozen_string_literal: true

class TemplatesArchivedController < ApplicationController
  def index
    templates = current_account.templates.where.not(deleted_at: nil).preload(:author).order(id: :desc)

    @pagy, @templates = pagy(templates, items: 12)
  end
end
