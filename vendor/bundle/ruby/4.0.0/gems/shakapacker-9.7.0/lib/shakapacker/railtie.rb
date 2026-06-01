require "rails/railtie"

require_relative "helper"
require_relative "dev_server_proxy"
require_relative "version_checker"
require_relative "utils/manager"

class Shakapacker::Engine < ::Rails::Engine
  # Allows Shakapacker config values to be set via Rails env config files
  config.shakapacker = ActiveSupport::OrderedOptions.new

  initializer "shakapacker.version_checker" do
    if File.exist?(Shakapacker::VersionChecker::NodePackageVersion.package_json_path)
      Shakapacker::VersionChecker.build.raise_if_gem_and_node_package_versions_differ
    end
  end

  initializer "shakapacker.manager_checker" do
    if File.exist?(Shakapacker::VersionChecker::NodePackageVersion.package_json_path)
      Shakapacker::Utils::Manager.error_unless_package_manager_is_obvious!
    end
  end

  initializer "shakapacker.proxy" do |app|
    if (Shakapacker.config.dev_server.present? rescue nil)
      app.middleware.insert_before 0,
        Rails::VERSION::MAJOR >= 5 ?
          Shakapacker::DevServerProxy : "Shakapacker::DevServerProxy", ssl_verify_none: true
    end
  end

  initializer "shakapacker.helper" do
    ActiveSupport.on_load :action_controller do
      ActionController::Base.helper Shakapacker::Helper
    end

    ActiveSupport.on_load :action_view do
      include Shakapacker::Helper
    end
  end

  # Early hints are handled automatically by javascript_pack_tag and stylesheet_pack_tag helpers
  # when early_hints.enabled: true in shakapacker.yml
  # See docs/early_hints_new_api.md for usage

  initializer "shakapacker.logger" do
    config.after_initialize do
      if ::Rails.logger.respond_to?(:tagged)
        Shakapacker.logger = ::Rails.logger
      else
        Shakapacker.logger = ActiveSupport::TaggedLogging.new(::Rails.logger)
      end
    end
  end

  initializer "shakapacker.bootstrap" do
    if defined?(Rails::Server) || defined?(Rails::Console)
      Shakapacker.bootstrap
      if defined?(Spring)
        require "spring/watcher"
        Spring.after_fork { Shakapacker.bootstrap }
        Spring.watch(Shakapacker.config.config_path)
      end
    end
  end

  initializer "shakapacker.set_source" do |app|
    if Shakapacker.config.config_path.exist?
      app.config.javascript_path = Shakapacker.config.source_path.relative_path_from(Rails.root.join("app")).to_s
    end
  end

  initializer "shakapacker.remove_app_packs_from_the_autoload_paths" do
    Rails.application.config.before_initialize do
      if Shakapacker.config.config_path.exist?
        source_path = Shakapacker.config.source_path.to_s
        ActiveSupport::Dependencies.autoload_paths.delete(source_path)
      end
    end
  end
end
