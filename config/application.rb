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
    config.load_defaults 8.1

    # Rails 8.x / Ruby 4.0 compatibility: several ActiveRecord class attributes
    # that were formerly configurable were permanently hardcoded and their setter
    # methods removed from ActiveRecord::Base.  load_defaults 8.1 still adds them
    # to the config.active_record hash (via cumulative 5.x-7.x defaults), and the
    # AR railtie's set_configs initializer blindly calls the setter for every key,
    # raising NoMethodError.  Deleting the keys here prevents the setters from
    # being called.
    %i[
      belongs_to_required_by_default
      has_many_inversing
      run_commit_callbacks_on_first_saved_instances_in_transaction
    ].each { |key| config.active_record.delete(key) }

    config.autoload_lib(ignore: %w[assets tasks puma])

    config.active_storage.routes_prefix = ''

    config.active_storage.draw_routes = ENV['MULTITENANT'] != 'true'

    config.i18n.available_locales = %i[en en-US en-GB es-ES fr-FR pt-PT de-DE it-IT nl-NL
                                       es it de fr nl pl uk cs pt he ar ko ja]
    config.i18n.fallbacks = [:en]

    config.exceptions_app = ->(env) { ErrorsController.action(:show).call(env) }

    config.content_security_policy_nonce_generator = ->(_) { SecureRandom.base64(16) }
    config.content_security_policy_nonce_directives = %w[script-src]

    config.action_view.frozen_string_literal = true

    config.middleware.insert_before ActionDispatch::Static, Rack::Deflater
    config.middleware.insert_before ActionDispatch::Static, NormalizeClientIpMiddleware
    config.middleware.insert_before ActionDispatch::Static, ApiPathConsiderJsonMiddleware

    config.generators.system_tests = nil

    autoloaders.once.do_not_eager_load("#{Turbo::Engine.root}/app/channels") # https://github.com/hotwired/turbo-rails/issues/512

    ActiveSupport.run_load_hooks(:application_config, self)
  end
end
