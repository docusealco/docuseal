# frozen_string_literal: true

module I18n
  class Middleware

    def initialize(app)
      @app = app
    end

    def call(env)
      @app.call(env)
    ensure
      Thread.current.thread_variable_set(:i18n_config, I18n::Config.new)
    end

  end
end
