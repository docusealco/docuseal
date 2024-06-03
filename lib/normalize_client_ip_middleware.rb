# frozen_string_literal: true

class NormalizeClientIpMiddleware
  def initialize(app)
    @app = app
  end

  def call(env)
    if env['HTTP_CLIENT_IP'].present? && env['HTTP_X_CLIENT_IP'].present? &&
       env['HTTP_CLIENT_IP'].starts_with?("#{env['HTTP_X_CLIENT_IP']}:")
      env['HTTP_CLIENT_IP'] = env['HTTP_X_CLIENT_IP']
    end

    @app.call(env)
  end
end
