# frozen_string_literal: true

module Seahorse
  module Client
    class Base

      include HandlerBuilder

      # default plugins
      # @api private
      @plugins = PluginList.new([
        Plugins::Endpoint,
        Plugins::NetHttp,
        Plugins::RaiseResponseErrors,
        Plugins::ResponseTarget,
        Plugins::RequestCallback
      ])

      # @api private
      def initialize(plugins, options)
        @config = build_config(plugins, options)
        @handlers = build_handler_list(plugins)
        after_initialize(plugins)
      end

      # @return [Configuration<Struct>]
      attr_reader :config

      # @return [HandlerList]
      attr_reader :handlers

      # Builds and returns a {Request} for the named operation.  The request
      # will not have been sent.
      # @param [Symbol, String] operation_name
      # @return [Request]
      def build_request(operation_name, params = {})
        Request.new(
          @handlers.for(operation_name),
          context_for(operation_name, params))
      end

      # @api private
      def inspect
        "#<#{self.class.name}>"
      end

      # @return [Array<Symbol>] Returns a list of valid request operation
      #   names. These are valid arguments to {#build_request} and are also
      #   valid methods.
      def operation_names
        self.class.api.operation_names - self.class.api.async_operation_names
      end

      private

      # Constructs a {Configuration} object and gives each plugin the
      # opportunity to register options with default values.
      def build_config(plugins, options)
        config = Configuration.new
        config.add_option(:api)
        config.add_option(:plugins)
        plugins.each do |plugin|
          plugin.add_options(config) if plugin.respond_to?(:add_options)
        end
        config.build!(options.merge(api: self.class.api))
      end

      # Gives each plugin the opportunity to register handlers for this client.
      def build_handler_list(plugins)
        plugins.inject(HandlerList.new) do |handlers, plugin|
          if plugin.respond_to?(:add_handlers)
            plugin.add_handlers(handlers, @config)
          end
          handlers
        end
      end

      # Gives each plugin the opportunity to modify this client.
      def after_initialize(plugins)
        plugins.reverse.each do |plugin|
          plugin.after_initialize(self) if plugin.respond_to?(:after_initialize)
        end
      end

      # @return [RequestContext]
      def context_for(operation_name, params)
        RequestContext.new(
          operation_name: operation_name,
          operation: config.api.operation(operation_name),
          client: self,
          params: params,
          config: config)
      end

      class << self

        def new(options = {})
          options = options.dup
          plugins = build_plugins(self.plugins + options.fetch(:plugins, []))
          plugins = before_initialize(plugins, options)
          client = allocate
          client.send(:initialize, plugins, options)
          client
        end

        # Registers a plugin with this client.
        #
        # @example Register a plugin
        #
        #   ClientClass.add_plugin(PluginClass)
        #
        # @example Register a plugin by name
        #
        #   ClientClass.add_plugin('gem-name.PluginClass')
        #
        # @example Register a plugin with an object
        #
        #   plugin = MyPluginClass.new(options)
        #   ClientClass.add_plugin(plugin)
        #
        # @param [Class, Symbol, String, Object] plugin
        # @see .clear_plugins
        # @see .set_plugins
        # @see .remove_plugin
        # @see .plugins
        # @return [void]
        def add_plugin(plugin)
          @plugins.add(plugin)
        end

        # @see .clear_plugins
        # @see .set_plugins
        # @see .add_plugin
        # @see .plugins
        # @return [void]
        def remove_plugin(plugin)
          @plugins.remove(plugin)
        end

        # @see .set_plugins
        # @see .add_plugin
        # @see .remove_plugin
        # @see .plugins
        # @return [void]
        def clear_plugins
          @plugins.set([])
        end

        # @param [Array<Plugin>] plugins
        # @see .clear_plugins
        # @see .add_plugin
        # @see .remove_plugin
        # @see .plugins
        # @return [void]
        def set_plugins(plugins)
          @plugins.set(plugins)
        end

        # Returns the list of registered plugins for this Client.  Plugins are
        # inherited from the client super class when the client is defined.
        # @see .clear_plugins
        # @see .set_plugins
        # @see .add_plugin
        # @see .remove_plugin
        # @return [Array<Plugin>]
        def plugins
          Array(@plugins).freeze
        end

        # @return [Model::Api]
        def api
          @api ||= Model::Api.new
        end

        # @param [Model::Api] api
        # @return [Model::Api]
        def set_api(api)
          @api = api
        end

        # @option options [Model::Api, Hash] :api ({})
        # @option options [Array<Plugin>] :plugins ([]) A list of plugins to
        #   add to the client class created.
        # @return [Class<Client::Base>]
        def define(options = {})
          subclass = Class.new(self)
          subclass.set_api(options[:api] || api)
          Array(options[:plugins]).each do |plugin|
            subclass.add_plugin(plugin)
          end
          subclass
        end
        alias extend define

        private

        def build_plugins(plugins)
          plugins.map { |plugin| plugin.is_a?(Class) ? plugin.new : plugin }
        end

        def before_initialize(plugins, options)
          queue = Queue.new
          plugins.each { |plugin| queue.push(plugin) }
          until queue.empty?
            plugin = queue.pop
            next unless plugin.respond_to?(:before_initialize)

            plugins_before = options.fetch(:plugins, [])
            plugin.before_initialize(self, options)
            plugins_after = build_plugins(options.fetch(:plugins, []) - plugins_before)
            # Plugins with before_initialize can add other plugins
            plugins_after.each { |p| queue.push(p); plugins << p }
          end
          plugins
        end

        def inherited(subclass)
          super
          subclass.instance_variable_set('@plugins', PluginList.new(@plugins))
        end

      end
    end
  end
end
