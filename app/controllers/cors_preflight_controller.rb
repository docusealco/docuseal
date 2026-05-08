# frozen_string_literal: true

class CorsPreflightController < ActionController::API
  include EmbedCors

  before_action :set_embed_cors_headers

  def show
    head :ok
  end
end
