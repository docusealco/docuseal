# frozen_string_literal: true

require_relative 'boot'

require 'active_record/railtie'
require 'active_storage/engine'
require 'action_controller/railtie'
require 'action_view/railtie'
require 'action_mailer/railtie'
require 'active_job/railtie'

require_relative '../lib/api_path_consider_json_middleware'

Bundler.require(*Rails.groups)

module DocuSeal
  class Application < Rails::Application
    config.load_defaults 7.0

    config.autoload_paths << Rails.root.join('lib')
    config.eager_load_paths << Rails.root.join('lib')

    config.active_storage.routes_prefix = ''

    config.i18n.available_locales = %i[en en-US en-GB es-ES pt-PT de-DE]
    config.i18n.fallbacks = [:en]

    config.action_view.frozen_string_literal = true

    config.middleware.insert_before ActionDispatch::Static, Rack::Deflater
    config.middleware.insert_before ActionDispatch::Static, ApiPathConsiderJsonMiddleware

    ActiveSupport.run_load_hooks(:application_config, self)
  end
end
