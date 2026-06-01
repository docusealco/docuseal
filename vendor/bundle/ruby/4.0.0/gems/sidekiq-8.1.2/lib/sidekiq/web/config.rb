# frozen_string_literal: true

module Sidekiq
  class Web
    ##
    # Configure the Sidekiq::Web instance in this process:
    #
    #   require "sidekiq/web"
    #   Sidekiq::Web.configure do |config|
    #     config.register(MyExtension, name: "myext", tab: "TabName", index: "tabpage/")
    #   end
    #
    # This should go in your `config/routes.rb` or similar. It
    # does not belong in your initializer since Web should not be
    # loaded in some processes (like an actual Sidekiq process).
    # See `examples/webui-ext` for a sample web extension.
    class Config
      extend Forwardable

      OPTIONS = {
        # By default we support direct uploads to p.f.c since the UI is a JS SPA
        # and very difficult for us to vendor or provide ourselves. If you are worried
        # about data security and wish to self-host, you can change these URLs.
        profile_view_url: "https://profiler.firefox.com/public/%s",
        profile_store_url: "https://api.profiler.firefox.com/compressed-store"
      }

      ##
      # Allows users to add custom rows to all of the Job
      # tables, e.g. Retries, Dead, Scheduled, with custom
      # links to other systems, see _job_info.erb and test
      # in web_test.rb
      #
      #   Sidekiq::Web.configure do |cfg|
      #     cfg.custom_job_info_rows << JobLogLink.new
      #   end
      #
      #   class JobLogLink
      #     def add_pair(job)
      #       yield "External Logs", "<a href='https://example.com/logs/#{job.jid}'>Logs for #{job.jid}</a>"
      #     end
      #   end
      attr_accessor :custom_job_info_rows

      attr_reader :tabs
      attr_reader :locales
      attr_reader :views
      attr_reader :middlewares

      # Adds the "Back to App" link in the header
      attr_accessor :app_url
      attr_accessor :assets_path

      def initialize
        @options = OPTIONS.dup
        @locales = LOCALES
        @views = VIEWS
        @assets_path = ASSETS
        @tabs = DEFAULT_TABS.dup
        @middlewares = []
        @custom_job_info_rows = []
      end

      def_delegators :@options, :[], :[]=, :fetch, :key?, :has_key?, :merge!, :dig

      def use(*args, &block)
        middlewares << [args, block]
      end

      # Register a class as a Sidekiq Web UI extension. The class should
      # provide one or more tabs which map to an index route. Options:
      #
      # @param extclass [Class] Class which contains the HTTP actions, required
      # @param name [String] the name of the extension, used to namespace assets
      # @param tab [String | Array] labels(s) of the UI tabs
      # @param index [String | Array] index route(s) for each tab
      # @param root_dir [String] directory location to find assets, locales and views, typically `web/` within the gemfile
      # @param asset_paths [Array] one or more directories under {root}/assets/{name} to be publicly served, e.g. ["js", "css", "img"]
      # @param cache_for [Integer] amount of time to cache assets, default one day
      #
      # Web extensions will have a root `web/` directory with `locales/`, `assets/`
      # and `views/` subdirectories.
      def register_extension(extclass, name:, tab:, index:, root_dir: nil, cache_for: 86400, asset_paths: nil)
        tab = Array(tab)
        index = Array(index)
        tab.zip(index).each do |tab, index|
          tabs[tab] = index
        end
        if root_dir
          locdir = File.join(root_dir, "locales")
          locales << locdir if File.directory?(locdir)

          if asset_paths && name
            # if you have {root}/assets/{name}/js/scripts.js
            # and {root}/assets/{name}/css/styles.css
            # you would pass in:
            #   asset_paths: ["js", "css"]
            # See script_tag and style_tag in web/helpers.rb
            assdir = File.join(root_dir, "assets")
            assurls = Array(asset_paths).map { |x| "/#{name}/#{x}" }
            assetprops = {
              urls: assurls,
              root: assdir,
              cascade: true
            }
            assetprops[:header_rules] = [[:all, {"cache-control" => "private, max-age=#{cache_for.to_i}"}]] if cache_for
            middlewares << [[Rack::Static, assetprops], nil]
          end
        end

        yield self if block_given?
        extclass.registered(Web::Application)
      end
      alias_method :register, :register_extension
    end
  end
end
