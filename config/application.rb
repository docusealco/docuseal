# frozen_string_literal: true

require_relative 'boot'

require 'active_record/railtie'
require 'active_storage/engine'
require 'action_controller/railtie'
require 'action_view/railtie'
require 'action_mailer/railtie'
require 'active_job/railtie'
require 'rails/health_controller'

require_relative '../lib/api_path_consider_json_middleware'
require_relative '../lib/normalize_client_ip_middleware'

Bundler.require(*Rails.groups)

module DocuSeal
  class Application < Rails::Application
    config.load_defaults 7.1

    config.autoload_lib(ignore: %w[assets tasks puma])

    config.active_storage.routes_prefix = ''

    config.active_storage.draw_routes = ENV['MULTITENANT'] != 'true'

    config.i18n.available_locales = %i[en en-US en-GB es-ES fr-FR pt-PT de-DE it-IT es it de fr pl uk cs pt he nl ar ko]
    config.i18n.fallbacks = [:en]

    config.exceptions_app = ->(env) { ErrorsController.action(:show).call(env) }

    config.action_view.frozen_string_literal = true

    config.middleware.insert_before ActionDispatch::Static, Rack::Deflater
    config.middleware.insert_before ActionDispatch::Static, NormalizeClientIpMiddleware
    config.middleware.insert_before ActionDispatch::Static, ApiPathConsiderJsonMiddleware

    config.generators.system_tests = nil

    autoloaders.once.do_not_eager_load("#{Turbo::Engine.root}/app/channels") # https://github.com/hotwired/turbo-rails/issues/512

    ActiveSupport.run_load_hooks(:application_config, self)
  end
end
