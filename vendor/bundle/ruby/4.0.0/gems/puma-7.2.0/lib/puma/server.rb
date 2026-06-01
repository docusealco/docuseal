# frozen_string_literal: true

require 'stringio'

require_relative 'thread_pool'
require_relative 'const'
require_relative 'log_writer'
require_relative 'events'
require_relative 'null_io'
require_relative 'reactor'
require_relative 'client'
require_relative 'binder'
require_relative 'util'
require_relative 'request'
require_relative 'configuration'
require_relative 'cluster_accept_loop_delay'

require 'socket'
require 'io/wait' unless Puma::HAS_NATIVE_IO_WAIT

module Puma
  # The HTTP Server itself. Serves out a single Rack app.
  #
  # This class is used by the `Puma::Single` and `Puma::Cluster` classes
  # to generate one or more `Puma::Server` instances capable of handling requests.
  # Each Puma process will contain one `Puma::Server` instance.
  #
  # The `Puma::Server` instance pulls requests from the socket, adds them to a
  # `Puma::Reactor` where they get eventually passed to a `Puma::ThreadPool`.
  #
  # Each `Puma::Server` will have one reactor and one thread pool.
  class Server
    module FiberPerRequest
      def handle_request(client, requests)
        Fiber.new do
          super
        end.resume
      end
    end

    include Puma::Const
    include Request

    attr_reader :options
    attr_reader :thread
    attr_reader :log_writer
    attr_reader :events
    attr_reader :min_threads, :max_threads  # for #stats
    attr_reader :requests_count             # @version 5.0.0

    # @todo the following may be deprecated in the future
    attr_reader :auto_trim_time, :early_hints, :first_data_timeout,
      :leak_stack_on_error,
      :persistent_timeout, :reaping_time

    attr_accessor :app
    attr_accessor :binder

    # Create a server for the rack app +app+.
    #
    # +log_writer+ is a Puma::LogWriter object used to log info and error messages.
    #
    # +events+ is a Puma::Events object used to notify application status events.
    #
    # Server#run returns a thread that you can join on to wait for the server
    # to do its work.
    #
    # @note Several instance variables exist so they are available for testing,
    #   and have default values set via +fetch+.  Normally the values are set via
    #   `::Puma::Configuration.puma_default_options`.
    #
    # @note The `events` parameter is set to nil, and set to `Events.new` in code.
    #   Often `options` needs to be passed, but `events` does not.  Using nil allows
    #   calling code to not require events.rb.
    #
    def initialize(app, events = nil, options = {})
      @app = app
      @events = events || Events.new

      @check, @notify = nil
      @status = :stop

      @thread = nil
      @thread_pool = nil
      @reactor = nil

      @env_set_http_version = nil

      @options = if options.is_a?(UserFileDefaultOptions)
        options
      else
        UserFileDefaultOptions.new(options, Configuration::DEFAULTS)
      end

      @clustered                 = (@options.fetch :workers, 0) > 0
      @worker_write              = @options[:worker_write]
      @log_writer                = @options.fetch :log_writer, LogWriter.stdio
      @early_hints               = @options[:early_hints]
      @first_data_timeout        = @options[:first_data_timeout]
      @persistent_timeout        = @options[:persistent_timeout]
      @idle_timeout              = @options[:idle_timeout]
      @min_threads               = @options[:min_threads]
      @max_threads               = @options[:max_threads]
      @queue_requests            = @options[:queue_requests]
      @max_keep_alive            = @options[:max_keep_alive]
      @enable_keep_alives        = @options[:enable_keep_alives]
      @enable_keep_alives      &&= @queue_requests
      @io_selector_backend       = @options[:io_selector_backend]
      @http_content_length_limit = @options[:http_content_length_limit]
      @cluster_accept_loop_delay = ClusterAcceptLoopDelay.new(
        workers: @options[:workers],
        max_delay: @options[:wait_for_less_busy_worker] || 0 # Real default is in Configuration::DEFAULTS, this is for unit testing
      )

      if @options[:fiber_per_request]
        singleton_class.prepend(FiberPerRequest)
      end

      # make this a hash, since we prefer `key?` over `include?`
      @supported_http_methods =
        if @options[:supported_http_methods] == :any
          :any
        else
          if (ary = @options[:supported_http_methods])
            ary
          else
            SUPPORTED_HTTP_METHODS
          end.sort.product([nil]).to_h.freeze
        end

      temp = !!(@options[:environment] =~ /\A(development|test)\z/)
      @leak_stack_on_error = @options[:environment] ? temp : true

      @binder = Binder.new(log_writer, @options)

      ENV['RACK_ENV'] ||= "development"

      @mode = :http

      @precheck_closing = true

      @requests_count = 0

      @idle_timeout_reached = false
    end

    def inherit_binder(bind)
      @binder = bind
    end

    class << self
      # @!attribute [r] current
      def current
        Thread.current.puma_server
      end

      # :nodoc:
      # @version 5.0.0
      def tcp_cork_supported?
        Socket.const_defined?(:TCP_CORK) && Socket.const_defined?(:IPPROTO_TCP)
      end

      # :nodoc:
      # @version 5.0.0
      def closed_socket_supported?
        Socket.const_defined?(:TCP_INFO) && Socket.const_defined?(:IPPROTO_TCP)
      end
      private :tcp_cork_supported?
      private :closed_socket_supported?
    end

    # On Linux, use TCP_CORK to better control how the TCP stack
    # packetizes our stream. This improves both latency and throughput.
    # socket parameter may be an MiniSSL::Socket, so use to_io
    #
    if tcp_cork_supported?
      # 6 == Socket::IPPROTO_TCP
      # 3 == TCP_CORK
      # 1/0 == turn on/off
      def cork_socket(socket)
        skt = socket.to_io
        begin
          skt.setsockopt(Socket::IPPROTO_TCP, Socket::TCP_CORK, 1) if skt.kind_of? TCPSocket
        rescue IOError, SystemCallError
        end
      end

      def uncork_socket(socket)
        skt = socket.to_io
        begin
          skt.setsockopt(Socket::IPPROTO_TCP, Socket::TCP_CORK, 0) if skt.kind_of? TCPSocket
        rescue IOError, SystemCallError
        end
      end
    else
      def cork_socket(socket)
      end

      def uncork_socket(socket)
      end
    end

    if closed_socket_supported?
      UNPACK_TCP_STATE_FROM_TCP_INFO = "C".freeze

      def closed_socket?(socket)
        skt = socket.to_io
        return false unless skt.kind_of?(TCPSocket) && @precheck_closing

        begin
          tcp_info = skt.getsockopt(Socket::IPPROTO_TCP, Socket::TCP_INFO)
        rescue IOError, SystemCallError
          @precheck_closing = false
          false
        else
          state = tcp_info.unpack(UNPACK_TCP_STATE_FROM_TCP_INFO)[0]
          # TIME_WAIT: 6, CLOSE: 7, CLOSE_WAIT: 8, LAST_ACK: 9, CLOSING: 11
          (state >= 6 && state <= 9) || state == 11
        end
      end
    else
      def closed_socket?(socket)
        false
      end
    end

    # @!attribute [r] backlog
    def backlog
      @thread_pool&.backlog
    end

    # @!attribute [r] running
    def running
      @thread_pool&.spawned
    end

    # This number represents the number of requests that
    # the server is capable of taking right now.
    #
    # For example if the number is 5 then it means
    # there are 5 threads sitting idle ready to take
    # a request. If one request comes in, then the
    # value would be 4 until it finishes processing.
    # @!attribute [r] pool_capacity
    def pool_capacity
      @thread_pool&.pool_capacity
    end

    # Runs the server.
    #
    # If +background+ is true (the default) then a thread is spun
    # up in the background to handle requests. Otherwise requests
    # are handled synchronously.
    #
    def run(background=true, thread_name: 'srv')
      BasicSocket.do_not_reverse_lookup = true

      @events.fire :state, :booting

      @status = :run

      @thread_pool = ThreadPool.new(thread_name, options, server: self) { |client| process_client client }

      if @queue_requests
        @reactor = Reactor.new(@io_selector_backend) { |c|
          # Inversion of control, the reactor is calling a method on the server when it
          # is done buffering a request or receives a new request from a keepalive connection.
          self.reactor_wakeup(c)
        }
        @reactor.run
      end

      @thread_pool.auto_reap! if options[:reaping_time]
      @thread_pool.auto_trim! if @min_threads != @max_threads && options[:auto_trim_time]

      @check, @notify = Puma::Util.pipe unless @notify

      @events.fire :state, :running

      if background
        @thread = Thread.new do
          Puma.set_thread_name thread_name
          handle_servers
        end
        return @thread
      else
        handle_servers
      end
    end

    # This method is called from the Reactor thread when a queued Client receives data,
    # times out, or when the Reactor is shutting down.
    #
    # While the code lives in the Server, the logic is executed on the reactor thread, independently
    # from the server.
    #
    # It is responsible for ensuring that a request has been completely received
    # before it starts to be processed by the ThreadPool. This may be known as read buffering.
    # If read buffering is not done, and no other read buffering is performed (such as by an application server
    # such as nginx) then the application would be subject to a slow client attack.
    #
    # For a graphical representation of how the request buffer works see [architecture.md](https://github.com/puma/puma/blob/main/docs/architecture.md).
    #
    # The method checks to see if it has the full header and body with
    # the `Puma::Client#try_to_finish` method. If the full request has been sent,
    # then the request is passed to the ThreadPool (`@thread_pool << client`)
    # so that a "worker thread" can pick up the request and begin to execute application logic.
    # The Client is then removed from the reactor (return `true`).
    #
    # If a client object times out, a 408 response is written, its connection is closed,
    # and the object is removed from the reactor (return `true`).
    #
    # If the Reactor is shutting down, all Clients are either timed out or passed to the
    # ThreadPool, depending on their current state (#can_close?).
    #
    # Otherwise, if the full request is not ready then the client will remain in the reactor
    # (return `false`). When the client sends more data to the socket the `Puma::Client` object
    # will wake up and again be checked to see if it's ready to be passed to the thread pool.
    def reactor_wakeup(client)
      shutdown = !@queue_requests
      if client.try_to_finish || (shutdown && !client.can_close?)
        @thread_pool << client
      elsif shutdown || client.timeout == 0
        client.timeout!
      else
        client.set_timeout(@first_data_timeout)
        false
      end
    rescue StandardError => e
      client_error(e, client)
      close_client_safely(client)
      true
    end

    def handle_servers
      @env_set_http_version = Object.const_defined?(:Rack) && ::Rack.respond_to?(:release) &&
        Gem::Version.new(::Rack.release) < Gem::Version.new('3.1.0')

      begin
        check = @check
        sockets = [check] + @binder.ios
        pool = @thread_pool
        queue_requests = @queue_requests
        drain = options[:drain_on_shutdown] ? 0 : nil

        addr_send_name, addr_value = case options[:remote_address]
        when :value
          [:peerip=, options[:remote_address_value]]
        when :header
          [:remote_addr_header=, options[:remote_address_header]]
        when :proxy_protocol
          [:expect_proxy_proto=, options[:remote_address_proxy_protocol]]
        else
          [nil, nil]
        end

        while @status == :run || (drain && shutting_down?)
          begin
            ios = IO.select sockets, nil, nil, (shutting_down? ? 0 : @idle_timeout)
            unless ios
              unless shutting_down?
                @idle_timeout_reached = true

                if @clustered
                  @worker_write << "#{PipeRequest::PIPE_IDLE}#{Process.pid}\n" rescue nil
                  next
                else
                  @log_writer.log "- Idle timeout reached"
                  @status = :stop
                end
              end

              break
            end

            if @idle_timeout_reached && @clustered
              @idle_timeout_reached = false
              @worker_write << "#{PipeRequest::PIPE_IDLE}#{Process.pid}\n" rescue nil
            end

            ios.first.each do |sock|
              if sock == check
                break if handle_check
              else
                # if ThreadPool out_of_band code is running, we don't want to add
                # clients until the code is finished.
                pool.wait_while_out_of_band_running

                # A well rested herd (cluster) runs faster
                if @cluster_accept_loop_delay.on? && (busy_threads_plus_todo = pool.busy_threads) > 0
                  delay = @cluster_accept_loop_delay.calculate(
                    max_threads: @max_threads,
                    busy_threads_plus_todo: busy_threads_plus_todo
                  )
                  sleep(delay)
                end

                io = begin
                  sock.accept_nonblock
                rescue IO::WaitReadable
                  next
                end
                drain += 1 if shutting_down?
                client = new_client(io, sock)
                client.send(addr_send_name, addr_value) if addr_value
                pool << client
              end
            end
          rescue IOError, Errno::EBADF
            # In the case that any of the sockets are unexpectedly close.
            raise
          rescue StandardError => e
            @log_writer.unknown_error e, nil, "Listen loop"
          end
        end

        @log_writer.debug "Drained #{drain} additional connections." if drain
        @events.fire :state, @status

        if queue_requests
          @queue_requests = false
          @reactor.shutdown
        end

        graceful_shutdown if @status == :stop || @status == :restart
      rescue Exception => e
        @log_writer.unknown_error e, nil, "Exception handling servers"
      ensure
        # Errno::EBADF is infrequently raised
        [@check, @notify].each do |io|
          begin
            io.close unless io.closed?
          rescue Errno::EBADF
          end
        end
        @notify = nil
        @check = nil
      end

      @events.fire :state, :done
    end

    # :nodoc:
    def new_client(io, sock)
      client = Client.new(io, @binder.env(sock))
      client.listener = sock
      client.http_content_length_limit = @http_content_length_limit
      client
    end

    # :nodoc:
    def handle_check
      cmd = @check.read(1)

      case cmd
      when STOP_COMMAND
        @status = :stop
        return true
      when HALT_COMMAND
        @status = :halt
        return true
      when RESTART_COMMAND
        @status = :restart
        return true
      end

      false
    end

    # Given a connection on +client+, handle the incoming requests,
    # or queue the connection in the Reactor if no request is available.
    #
    # This method is called from a ThreadPool worker thread.
    #
    # This method supports HTTP Keep-Alive so it may, depending on if the client
    # indicates that it supports keep alive, wait for another request before
    # returning.
    #
    # Return true if one or more requests were processed.
    def process_client(client)
      close_socket = true

      requests = 0

      begin
        if @queue_requests && !client.eagerly_finish

          client.set_timeout(@first_data_timeout)
          if @reactor.add client
            close_socket = false
            return false
          end
        end

        with_force_shutdown(client) do
          client.finish(@first_data_timeout)
        end

        can_loop = true
        while can_loop
          can_loop = false
          @requests_count += 1
          case handle_request(client, requests + 1)
          when :close
          when :async
            close_socket = false
          when :keep_alive
            requests += 1

            client.reset

            # This indicates data exists in the client read buffer and there may be
            # additional requests on it, so process them
            next_request_ready = if client.has_back_to_back_requests?
              with_force_shutdown(client) { client.process_back_to_back_requests }
            else
              with_force_shutdown(client) { client.eagerly_finish }
            end

            if next_request_ready
              # When Puma has spare threads, allow this one to be monopolized
              # Perf optimization for https://github.com/puma/puma/issues/3788
              if @thread_pool.waiting > 0
                can_loop = true
              else
                @thread_pool << client
                close_socket = false
              end
            elsif @queue_requests
              client.set_timeout @persistent_timeout
              if @reactor.add client
                close_socket = false
              end
            end
          end
        end
        true
      rescue StandardError => e
        client_error(e, client, requests)
        # The ensure tries to close +client+ down
        requests > 0
      ensure
        client.io_buffer.reset

        close_client_safely(client) if close_socket
      end
    end

    # :nodoc:
    def close_client_safely(client)
      client.close
    rescue IOError, SystemCallError
      # Already closed
    rescue MiniSSL::SSLError => e
      @log_writer.ssl_error e, client.io
    rescue StandardError => e
      @log_writer.unknown_error e, nil, "Client"
    end

    # Triggers a client timeout if the thread-pool shuts down
    # during execution of the provided block.
    def with_force_shutdown(client, &block)
      @thread_pool.with_force_shutdown(&block)
    rescue ThreadPool::ForceShutdown
      client.timeout!
    end

    # :nocov:

    # Handle various error types thrown by Client I/O operations.
    def client_error(e, client, requests = 1)
      # Swallow, do not log
      return if [ConnectionError, EOFError].include?(e.class)

      case e
      when MiniSSL::SSLError
        lowlevel_error(e, client.env)
        @log_writer.ssl_error e, client.io
      when HttpParserError
        response_to_error(client, requests, e, 400)
        @log_writer.parse_error e, client
      when HttpParserError501
        response_to_error(client, requests, e, 501)
        @log_writer.parse_error e, client
      else
        response_to_error(client, requests, e, 500)
        @log_writer.unknown_error e, nil, "Read"
      end
    end

    # A fallback rack response if +@app+ raises as exception.
    #
    def lowlevel_error(e, env, status=500)
      if handler = options[:lowlevel_error_handler]
        if handler.arity == 1
          return handler.call(e)
        elsif handler.arity == 2
          return handler.call(e, env)
        else
          return handler.call(e, env, status)
        end
      end

      if @leak_stack_on_error
        backtrace = e.backtrace.nil? ? '<no backtrace available>' : e.backtrace.join("\n")
        [status, {}, ["Puma caught this error: #{e.message} (#{e.class})\n#{backtrace}"]]
      else
        [status, {}, [""]]
      end
    end

    def response_to_error(client, requests, err, status_code)
      status, headers, res_body = lowlevel_error(err, client.env, status_code)
      prepare_response(status, headers, res_body, requests, client)
    end
    private :response_to_error

    # Wait for all outstanding requests to finish.
    #
    def graceful_shutdown
      if options[:shutdown_debug]
        threads = Thread.list
        total = threads.size

        pid = Process.pid

        $stdout.syswrite "#{pid}: === Begin thread backtrace dump ===\n"

        threads.each_with_index do |t,i|
          $stdout.syswrite "#{pid}: Thread #{i+1}/#{total}: #{t.inspect}\n"
          $stdout.syswrite "#{pid}: #{t.backtrace.join("\n#{pid}: ")}\n\n"
        end
        $stdout.syswrite "#{pid}: === End thread backtrace dump ===\n"
      end

      if @status != :restart
        @binder.close
      end

      if @thread_pool
        if timeout = options[:force_shutdown_after]
          @thread_pool.shutdown timeout.to_f
        else
          @thread_pool.shutdown
        end
      end
    end

    def notify_safely(message)
      @notify << message
    rescue IOError, NoMethodError, Errno::EPIPE, Errno::EBADF
      # The server, in another thread, is shutting down
    rescue RuntimeError => e
      # Temporary workaround for https://bugs.ruby-lang.org/issues/13239
      if e.message.include?('IOError')
        # ignore
      else
        raise e
      end
    end
    private :notify_safely

    # Stops the acceptor thread and then causes the worker threads to finish
    # off the request queue before finally exiting.

    def stop(sync=false)
      notify_safely(STOP_COMMAND)
      @thread.join if @thread && sync
    end

    def halt(sync=false)
      notify_safely(HALT_COMMAND)
      @thread.join if @thread && sync
    end

    def begin_restart(sync=false)
      notify_safely(RESTART_COMMAND)
      @thread.join if @thread && sync
    end

    def shutting_down?
      @status == :stop || @status == :restart
    end

    # List of methods invoked by #stats.
    # @version 5.0.0
    STAT_METHODS = [
      :backlog,
      :running,
      :pool_capacity,
      :busy_threads,
      :backlog_max,
      :max_threads,
      :requests_count,
      :reactor_max,
    ].freeze

    # Returns a hash of stats about the running server for reporting purposes.
    # @version 5.0.0
    # @!attribute [r] stats
    # @return [Hash] hash containing stat info from `Server` and `ThreadPool`
    def stats
      stats = @thread_pool&.stats || {}
      stats[:max_threads]    = @max_threads
      stats[:requests_count] = @requests_count
      stats[:reactor_max] = @reactor.reactor_max if @reactor
      reset_max
      stats
    end

    def reset_max
      @reactor.reactor_max = 0 if @reactor
      @thread_pool&.reset_max
    end

    # below are 'delegations' to binder
    # remove in Puma 7?


    def add_tcp_listener(host, port, optimize_for_latency = true, backlog = 1024)
      @binder.add_tcp_listener host, port, optimize_for_latency, backlog
    end

    def add_ssl_listener(host, port, ctx, optimize_for_latency = true,
                         backlog = 1024)
      @binder.add_ssl_listener host, port, ctx, optimize_for_latency, backlog
    end

    def add_unix_listener(path, umask = nil, mode = nil, backlog = 1024)
      @binder.add_unix_listener path, umask, mode, backlog
    end

    # @!attribute [r] connected_ports
    def connected_ports
      @binder.connected_ports
    end
  end
end
