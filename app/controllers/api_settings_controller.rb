# frozen_string_literal: true

class ApiSettingsController < ApplicationController
  def index
    authorize!(:read, current_user.access_token)
  end
end
