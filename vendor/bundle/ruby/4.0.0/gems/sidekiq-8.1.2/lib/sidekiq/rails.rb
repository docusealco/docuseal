# frozen_string_literal: true

module Sidekiq
  begin
    gem "railties", ">= 7.0"
    require "rails"
    require "sidekiq/job"
    require_relative "../active_job/queue_adapters/sidekiq_adapter"

    class Rails < ::Rails::Engine
      class Reloader
        def initialize(app = ::Rails.application)
          @app = app
        end

        def call
          params = (::Rails::VERSION::STRING >= "7.1") ? {source: "job.sidekiq"} : {}
          @app.reloader.wrap(**params) do
            yield
          end
        end

        def inspect
          "#<Sidekiq::Rails::Reloader @app=#{@app.class.name}>"
        end

        def to_hash
          {app: @app.class.name}
        end
      end

      initializer "sidekiq.backtrace_cleaner" do
        Sidekiq.configure_server do |config|
          config[:backtrace_cleaner] = ->(backtrace) { ::Rails.backtrace_cleaner.clean(backtrace) }
        end
      end

      # This hook happens after all initializers are run, just before returning
      # from config/environment.rb back to sidekiq/cli.rb.
      #
      # None of this matters on the client-side, only within the Sidekiq process itself.
      config.after_initialize do
        Sidekiq.configure_server do |config|
          config[:reloader] = Sidekiq::Rails::Reloader.new

          # This is the integration code necessary so that if a job uses `Rails.logger.info "Hello"`,
          # it will appear in the Sidekiq console with all of the job context.
          unless ::Rails.logger == config.logger || ::ActiveSupport::Logger.logger_outputs_to?(::Rails.logger, $stdout)
            if ::Rails.logger.respond_to?(:broadcast_to)
              ::Rails.logger.broadcast_to(config.logger)
            elsif ::ActiveSupport::Logger.respond_to?(:broadcast)
              ::Rails.logger.extend(::ActiveSupport::Logger.broadcast(config.logger))
            else
              ::Rails.logger = ::ActiveSupport::BroadcastLogger.new(::Rails.logger, config.logger)
            end
          end
        end
      end
    end
  rescue Gem::LoadError
    # Rails not available or version requirement not met
  end
end
