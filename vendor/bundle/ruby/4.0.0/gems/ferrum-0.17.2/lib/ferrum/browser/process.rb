# frozen_string_literal: true

require "net/http"
require "json"
require "addressable"
require "tmpdir"
require "forwardable"
require "ferrum/browser/options/base"
require "ferrum/browser/options/chrome"
require "ferrum/browser/options/firefox"
require "ferrum/browser/command"
require "ferrum/utils/elapsed_time"
require "ferrum/utils/platform"

module Ferrum
  class Browser
    class Process
      KILL_TIMEOUT = 2
      WAIT_KILLED = 0.05

      extend Forwardable

      delegate path: :command

      def self.start(*args)
        new(*args).tap(&:start)
      end

      def self.process_killer(pid)
        proc do
          if Utils::Platform.windows?
            # Process.kill is unreliable on Windows
            ::Process.kill("KILL", pid) unless system("taskkill /f /t /pid #{pid} >NUL 2>NUL")
          else
            ::Process.kill("USR1", pid)
            start = Utils::ElapsedTime.monotonic_time
            while ::Process.wait(pid, ::Process::WNOHANG).nil?
              sleep(WAIT_KILLED)
              next unless Utils::ElapsedTime.timeout?(start, KILL_TIMEOUT)

              ::Process.kill("KILL", pid)
              ::Process.wait(pid)
              break
            end
          end
        rescue Errno::ESRCH, Errno::ECHILD
          # nop
        end
      end

      def self.directory_remover(path)
        proc {
          begin
            FileUtils.remove_entry(path)
          rescue StandardError
            Errno::ENOENT
          end
        }
      end

      attr_reader :host, :port, :ws_url, :pid, :command,
                  :default_user_agent, :browser_version, :protocol_version,
                  :v8_version, :webkit_version, :xvfb

      def initialize(options)
        @pid = @xvfb = @user_data_dir = nil

        if options.ws_url || options.url
          # `:ws_url` option is higher priority than `:url`, parse versions
          # and use it as a ws_url, otherwise use what has been parsed.
          response = parse_json_version(options.ws_url || options.url)
          self.ws_url = options.ws_url || response&.[]("webSocketDebuggerUrl")
          return
        end

        @logger = options.logger
        @process_timeout = options.process_timeout
        @env = Hash(options.env)

        tmpdir = Dir.mktmpdir("ferrum_user_data_dir_")
        ObjectSpace.define_finalizer(self, self.class.directory_remover(tmpdir))
        @user_data_dir = tmpdir
        @command = Command.build(options, tmpdir)
      end

      def start
        # Don't do anything as browser is already running as external process.
        return if ws_url

        begin
          read_io, write_io = IO.pipe
          process_options = { in: File::NULL }
          process_options[:pgroup] = true unless Utils::Platform.windows?
          process_options[:out] = process_options[:err] = write_io

          if @command.xvfb?
            @xvfb = Xvfb.start(@command.options)
            ObjectSpace.define_finalizer(self, self.class.process_killer(@xvfb.pid))
          end

          env = Hash(@xvfb&.to_env).merge(@env)
          @pid = ::Process.spawn(env, *@command.to_a, process_options)
          ObjectSpace.define_finalizer(self, self.class.process_killer(@pid))

          parse_ws_url(read_io, @process_timeout)
          parse_json_version(ws_url)
        ensure
          close_io(read_io, write_io)
        end
      end

      def stop
        if @pid
          kill(@pid)
          kill(@xvfb.pid) if @xvfb&.pid
          @pid = nil
        end

        remove_user_data_dir if @user_data_dir
        ObjectSpace.undefine_finalizer(self)
      end

      def restart
        stop
        start
      end

      def inspect
        "#<#{self.class} " \
          "@user_data_dir=#{@user_data_dir.inspect} " \
          "@command=#<#{@command.class}:#{@command.object_id}> " \
          "@default_user_agent=#{@default_user_agent.inspect} " \
          "@ws_url=#{@ws_url.inspect} " \
          "@v8_version=#{@v8_version.inspect} " \
          "@browser_version=#{@browser_version.inspect} " \
          "@webkit_version=#{@webkit_version.inspect}>"
      end

      private

      def kill(pid)
        self.class.process_killer(pid).call
      end

      def remove_user_data_dir
        self.class.directory_remover(@user_data_dir).call
        @user_data_dir = nil
      end

      def parse_ws_url(read_io, timeout)
        output = ""
        start = Utils::ElapsedTime.monotonic_time
        max_time = start + timeout
        regexp = %r{DevTools listening on (ws://.*[a-zA-Z0-9-]{36})}
        while (now = Utils::ElapsedTime.monotonic_time) < max_time
          begin
            output += read_io.read_nonblock(512)
          rescue IO::WaitReadable
            read_io.wait_readable(max_time - now)
          else
            if output.match(regexp)
              self.ws_url = output.match(regexp)[1].strip
              break
            end
          end
        end

        return if ws_url

        @logger&.puts(output)
        raise ProcessTimeoutError.new(timeout, output)
      end

      def ws_url=(url)
        @ws_url = Addressable::URI.parse(url)
        @host = @ws_url.host
        @port = @ws_url.port
      end

      def close_io(*ios)
        ios.each do |io|
          io.close if io && !io.closed?
        rescue IOError
          raise unless RUBY_ENGINE == "jruby"
        end
      end

      def parse_json_version(url)
        url = URI.join(url, "/json/version")

        if %w[wss ws].include?(url.scheme)
          url.scheme = case url.scheme
                       when "ws"
                         "http"
                       when "wss"
                         "https"
                       end
        end

        response = JSON.parse(::Net::HTTP.get(URI(url.to_s)))

        @v8_version = response["V8-Version"]
        @browser_version = response["Browser"]
        @webkit_version = response["WebKit-Version"]
        @default_user_agent = response["User-Agent"]
        @protocol_version = response["Protocol-Version"]

        response
      rescue JSON::ParserError
        # nop
      end
    end
  end
end
