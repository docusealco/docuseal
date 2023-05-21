# frozen_string_literal: true

require_relative 'boot'

require 'active_record/railtie'
require 'active_storage/engine'
require 'action_controller/railtie'
require 'action_view/railtie'
require 'action_mailer/railtie'
require 'active_job/railtie'

Bundler.require(*Rails.groups)

module Docuseal
  class Application < Rails::Application
    config.load_defaults 7.0

    config.autoload_paths << Rails.root.join('lib')
    config.eager_load_paths << Rails.root.join('lib')

    config.active_storage.routes_prefix = ''
  end
end
