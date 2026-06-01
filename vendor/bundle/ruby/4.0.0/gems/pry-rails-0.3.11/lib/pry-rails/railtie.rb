# encoding: UTF-8

module PryRails
  class Railtie < Rails::Railtie
    console do
      require 'pry'
      require 'pry-rails/commands'

      if Rails::VERSION::MAJOR == 3
        Rails::Console::IRB = Pry

        unless defined? Pry::ExtendCommandBundle
          Pry::ExtendCommandBundle = Module.new
        end
      end

      if Rails::VERSION::MAJOR >= 4
        Rails.application.config.console = Pry
      end

      major = Rails::VERSION::MAJOR
      minor = Rails::VERSION::MINOR

      if (major == 3 && minor >= 2) || (major >= 4 && (major < 7 || (major == 7 && minor < 2)))
        require "rails/console/app"
        require "rails/console/helpers"
        TOPLEVEL_BINDING.eval('self').extend ::Rails::ConsoleMethods
      end

      if major > 7 || (major == 7 && minor >= 2)
        require "rails/commands/console/irb_console"

        Module.new do
          def reload!
            puts "Reloading..."
            Rails.application.reloader.reload!
          end

          ::IRB::HelperMethod.helper_methods.each do |name, helper_method_class|
            define_method name do |*args, **opts, &block|
              helper_method_class.instance.execute(*args, **opts, &block)
            end
          end

          TOPLEVEL_BINDING.eval("self").extend self
        end
      end
    end
  end
end
