# frozen_string_literal: true

class DashboardController < ApplicationController
  def index
    @templates = current_account.templates.active
  end
end
