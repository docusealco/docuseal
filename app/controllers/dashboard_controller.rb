# frozen_string_literal: true

class DashboardController < ApplicationController
  skip_before_action :authenticate_user!, only: %i[index]

  def index
    return redirect_to Docuseal::PRODUCT_URL, allow_other_host: true if Docuseal.multitenant? && !signed_in?
    return render 'pages/landing' unless signed_in?

    templates = current_account.templates.active.preload(:author).order(id: :desc)
    templates = Templates.search(templates, params[:q])

    @pagy, @templates = pagy(templates, items: 12)
  end
end
