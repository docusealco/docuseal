# frozen_string_literal: true

class DashboardController < ApplicationController
  skip_before_action :authenticate_user!, only: %i[index]

  def index
    return render 'pages/landing' unless signed_in?

    @pagy, @templates = pagy(current_account.templates.active, items: 12)
  end
end
