# frozen_string_literal: true

require "erb"

module Sidekiq
  class Web
    ##
    # These instance methods are available to all executing ERB
    # templates.
    class Action
      attr_accessor :env, :block

      def initialize(env, block)
        @_erb = false
        @env = env
        @block = block
      end

      def config
        env[:web_config]
      end

      def request
        @request ||= ::Rack::Request.new(env)
      end

      def halt(res)
        throw :halt, [res, {"content-type" => "text/plain"}, [res.to_s]]
      end

      # external redirect
      def redirect_to(url)
        throw :halt, [302, {"location" => url}, []]
      end

      def header(key, value)
        env["response_headers"][key] = value.to_s
      end

      # internal redirect
      def redirect(location)
        throw :halt, [302, {"location" => "#{request.base_url}#{location}"}, []]
      end

      def reload_page
        current_location = request.referer.gsub(request.base_url, "")
        redirect current_location
      end

      # stuff after ? or form input
      # uses String keys, no Symbols!
      def url_params(key)
        warn { "URL parameter `#{key}` should be accessed via String, not Symbol (at #{caller(3..3).first})" } if key.is_a?(Symbol)
        request.params[key.to_s]
      end

      # variables embedded in path, `/metrics/:name`
      # uses Symbol keys, no Strings!
      def route_params(key)
        warn { "Route parameter `#{key}` should be accessed via Symbol, not String (at #{caller(3..3).first})" } if key.is_a?(String)
        env["rack.route_params"][key.to_sym]
      end

      def params
        warn { "Direct access to Rack parameters is discouraged, use `url_params` or `route_params` (at #{caller(3..3).first})" }
        request.params
      end

      def session
        env["rack.session"] || fail(<<~EOM)
          Sidekiq::Web needs a valid Rack session. If this is a Rails app, make
          sure you mount Sidekiq::Web *inside* your application routes:


          Rails.application.routes.draw do
            mount Sidekiq::Web => "/sidekiq"
            ....
          end


          If this is a Rails app in API mode, you need to enable sessions.

            https://guides.rubyonrails.org/api_app.html#using-session-middlewares

          If this is a bare Rack app, use a session middleware before Sidekiq::Web:

            # first, use IRB to create a shared secret key for sessions and commit it
            require 'securerandom'; File.open(".session.key", "w") {|f| f.write(SecureRandom.hex(32)) }

            # now use the secret with a session cookie middleware
            use Rack::Session::Cookie, secret: File.read(".session.key"), same_site: true, max_age: 86400
            run Sidekiq::Web

        EOM
      end

      def logger
        Sidekiq.logger
      end

      # flash { "Some message to show on redirect" }
      def flash
        msg = yield
        logger.info msg
        session[:skq_flash] = msg
      end

      def flash?
        session&.[](:skq_flash)
      end

      def get_flash
        @flash ||= session.delete(:skq_flash)
      end

      def erb(content, options = {})
        if content.is_a? Symbol
          unless respond_to?(:"_erb_#{content}")
            views = options[:views] || Web.views
            filename = "#{views}/#{content}.html.erb"
            src = ERB.new(File.read(filename)).src

            # Need to use lineno less by 1 because erb generates a
            # comment before the source code.
            Action.class_eval <<-RUBY, filename, -1 # standard:disable Style/EvalWithLocation
              def _erb_#{content}
                #{src}
              end
            RUBY
          end
        end

        if @_erb
          _erb(content, options[:locals])
        else
          @_erb = true
          content = _erb(content, options[:locals])

          _render { content }
        end
      end

      def render(engine, content, options = {})
        raise "Only erb templates are supported" if engine != :erb

        erb(content, options)
      end

      def json(payload)
        [200,
          {"content-type" => "application/json", "cache-control" => "private, no-store"},
          [Sidekiq.dump_json(payload)]]
      end

      private

      def warn
        Sidekiq.logger.warn yield
      end

      def _erb(file, locals)
        locals&.each { |k, v| define_singleton_method(k) { v } unless singleton_methods.include? k }

        if file.is_a?(String)
          ERB.new(file).result(binding)
        else
          send(:"_erb_#{file}")
        end
      end

      class_eval <<-RUBY, ::Sidekiq::Web::LAYOUT, -1 # standard:disable Style/EvalWithLocation
        def _render
          #{ERB.new(File.read(::Sidekiq::Web::LAYOUT)).src}
        end
      RUBY
    end
  end
end
