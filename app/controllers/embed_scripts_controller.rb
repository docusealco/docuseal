# frozen_string_literal: true

class EmbedScriptsController < ActionController::Metal
  def show
    headers['Content-Type'] = 'application/javascript'

    self.response_body = ''

    self.status = 200
  end
end
