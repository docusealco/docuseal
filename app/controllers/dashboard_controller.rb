# frozen_string_literal: true

class DashboardController < ApplicationController
  skip_before_action :authenticate_user!, only: %i[index]

  before_action :maybe_redirect_product_url
  before_action :maybe_render_landing

  load_and_authorize_resource :template, parent: false

  def index
    @templates = @templates.active.preload(:author).order(id: :desc)
    @templates = Templates.search(@templates, params[:q])

    @pagy, @templates = pagy(@templates, items: 12)
  end

  private

  def maybe_redirect_product_url
    return if !Docuseal.multitenant? || signed_in?

    redirect_to Docuseal::PRODUCT_URL, allow_other_host: true
  end

  def maybe_render_landing
    return if signed_in?

    render 'pages/landing'
  end
end
