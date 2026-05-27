# frozen_string_literal: true

require "erb"
require "securerandom"
require "rack/builder"
require "rack/static"
require "sidekiq"
require "sidekiq/api"
require "sidekiq/web/config"

module Sidekiq
  class Web
    ROOT = File.expand_path("#{File.dirname(__FILE__)}/../../web")
    VIEWS = "#{ROOT}/views"
    LOCALES = ["#{ROOT}/locales"]
    LAYOUT = "#{VIEWS}/layout.html.erb"
    ASSETS = "#{ROOT}/assets"

    DEFAULT_TABS = {
      "Dashboard" => "",
      "Busy" => "busy",
      "Queues" => "queues",
      "Retries" => "retries",
      "Scheduled" => "scheduled",
      "Dead" => "morgue",
      "Metrics" => "metrics",
      "Profiles" => "profiles"
    }

    @@config = Sidekiq::Web::Config.new

    class << self
      def configure
        if block_given?
          yield @@config
        else
          @@config
        end
      end

      def app_url=(url)
        @@config.app_url = url
      end

      def assets_path=(path)
        @@config.assets_path = path
      end

      def assets_path = @@config.assets_path

      def tabs = @@config.tabs

      def locales = @@config.locales

      def views = @@config.views

      def custom_job_info_rows = @@config.custom_job_info_rows

      def redis_pool
        @pool || Sidekiq.default_configuration.redis_pool
      end

      def redis_pool=(pool)
        @pool = pool
      end

      def middlewares = @@config.middlewares

      def use(*args, &block) = @@config.middlewares << [args, block]

      def register(*args, **kw, &block)
        Sidekiq.logger.warn { "`Sidekiq::Web.register` is deprecated, use `Sidekiq::Web.configure {|cfg| cfg.register(...) }`" }
        @@config.register(*args, **kw, &block)
      end
    end

    # Allow user to say
    #   run Sidekiq::Web
    # rather than:
    #   run Sidekiq::Web.new
    def self.call(env)
      @inst ||= new
      @inst.call(env)
    end

    # testing, internal use only
    def self.reset!
      @@config.reset!
      @inst = nil
    end

    def call(env)
      env[:web_config] = Sidekiq::Web.configure
      env[:csp_nonce] = SecureRandom.hex(8)
      env[:redis_pool] = self.class.redis_pool
      safe_request?(env) ? app.call(env) : deny(env)
    end

    def app
      @app ||= build(@@config)
    end

    def safe_methods?(env)
      %w[GET HEAD OPTIONS TRACE].include? env["REQUEST_METHOD"]
    end

    def safe_request?(env)
      return true if safe_methods?(env)
      env["HTTP_SEC_FETCH_SITE"] == "same-origin"
    end

    def deny(env)
      Sidekiq.logger.warn "attack prevented by #{self.class}"
      [403, {Rack::CONTENT_TYPE => "text/plain"}, ["Forbidden"]]
    end

    private

    def build(cfg)
      cfg.freeze
      m = cfg.middlewares

      rules = []
      rules = [[:all, {"cache-control" => "private, max-age=86400"}]] unless ENV["SIDEKIQ_WEB_TESTING"]

      ::Rack::Builder.new do
        use Rack::Static, urls: ["/stylesheets", "/images", "/javascripts"],
          root: cfg.assets_path,
          cascade: true,
          header_rules: rules
        m.each { |middleware, block| use(*middleware, &block) }
        run Sidekiq::Web::Application.new(self.class)
      end
    end
  end
end

require "sidekiq/web/router"
require "sidekiq/web/action"
require "sidekiq/web/application"
