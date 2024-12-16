# frozen_string_literal: true

class SubmissionsFiltersController < ApplicationController
  ALLOWED_NAMES = %w[
    author
    completed_at
    status
    created_at
  ].freeze

  skip_authorization_check

  def show
    return head :not_found unless ALLOWED_NAMES.include?(params[:name])

    render params[:name]
  end
end
