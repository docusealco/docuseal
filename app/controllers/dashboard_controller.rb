# frozen_string_literal: true

class DashboardController < ApplicationController
  def index
    @flows = current_account.flows.active
  end
end
