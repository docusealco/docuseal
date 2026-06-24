# frozen_string_literal: true

class TemplatesSharedController < ApplicationController
  def index
    authorize!(:read, Template)

    @templates = Templates.shared(current_user)
                          .active
                          .preload(:author, :template_accesses, :template_sharings)
                          .order(id: :desc)

    @templates = Templates.search(current_user, @templates, params[:q])

    @pagy, @templates = pagy_auto(@templates, limit: 12)
  end
end
