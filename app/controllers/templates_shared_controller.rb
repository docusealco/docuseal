# frozen_string_literal: true

class TemplatesSharedController < ApplicationController
  def index
    authorize!(:read, Template)

    @is_archived = params[:archived] == 'true'

    @templates = Templates.shared(current_user)

    @has_archived = !@is_archived && @templates.archived.exists?

    @templates = @is_archived ? @templates.archived : @templates.active

    @templates = @templates.preload(:author, :template_accesses, :template_sharings)
                           .order(id: :desc)

    @templates = Templates.search(current_user, @templates, params[:q])

    @pagy, @templates = pagy_auto(@templates, limit: 12)
  end
end
