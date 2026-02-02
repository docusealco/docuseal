# frozen_string_literal: true

class NormalizeClientIpMiddleware
  def initialize(app)
    @app = app
  end

  def call(env)
    if env['HTTP_CLIENT_IP'].present?
      if env['HTTP_X_CLIENT_IP'].present? &&
         env['HTTP_CLIENT_IP'].starts_with?("#{env['HTTP_X_CLIENT_IP']}:")
        env['HTTP_CLIENT_IP'] = env['HTTP_X_CLIENT_IP']
      end

      if env['HTTP_X_FORWARDED_FOR'].present? &&
         env['HTTP_X_FORWARDED_FOR'].sub(/:\d+\z/, '') == env['HTTP_CLIENT_IP']
        env['HTTP_X_FORWARDED_FOR'] = env['HTTP_CLIENT_IP']
      end
    end

    @app.call(env)
  end
end
