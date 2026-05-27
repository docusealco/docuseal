# frozen_string_literal: true

require "socket"
require "trilogy/version"
require "trilogy/error"
require "trilogy/result"
require "trilogy/cext"
require "trilogy/encoding"

class Trilogy
  IO_TIMEOUT_ERROR =
    if defined?(IO::TimeoutError)
      IO::TimeoutError
    else
      Class.new(StandardError)
    end
  private_constant :IO_TIMEOUT_ERROR

  module Synchronization
    def initialize(...)
      @mutex = Mutex.new
      super
    end

    synchronized_methods = Trilogy.public_instance_methods(false) - %i(closed?)
    source = synchronized_methods.flat_map do |method|
      [
        "def #{method}(...)",
          "raise SynchronizationError unless @mutex.try_lock",
          "begin",
            "super",
          "ensure",
            "@mutex.unlock",
          "end",
        "end",
      ]
    end
    class_eval(source.join(";"), __FILE__, __LINE__)
  end

  prepend(Synchronization)

  def initialize(options = {})
    options[:port] = options[:port].to_i if options[:port]
    mysql_encoding = options[:encoding] || "utf8mb4"
    encoding = Trilogy::Encoding.find(mysql_encoding)
    charset = Trilogy::Encoding.charset(mysql_encoding)
    @connection_options = options
    @connected_host = nil

    socket = nil
    begin
      if host = options[:host]
        port = options[:port] || 3306
        connect_timeout = options[:connect_timeout] || options[:write_timeout]

        socket = TCPSocket.new(host, port, connect_timeout: connect_timeout)

        socket.setsockopt(Socket::IPPROTO_TCP, Socket::TCP_NODELAY, 1)

        if keepalive_enabled = options[:keepalive_enabled]
          keepalive_idle = options[:keepalive_idle]
          keepalive_interval = options[:keepalive_interval]
          keepalive_count = options[:keepalive_count]

          socket.setsockopt(Socket::SOL_SOCKET, Socket::SO_KEEPALIVE, true)

          if keepalive_idle > 0 && defined?(Socket::TCP_KEEPIDLE)
            socket.setsockopt(Socket::IPPROTO_TCP, Socket::TCP_KEEPIDLE, keepalive_idle)
          end
          if keepalive_interval > 0 && defined?(Socket::TCP_KEEPINTVL)
            socket.setsockopt(Socket::IPPROTO_TCP, Socket::TCP_KEEPINTVL, keepalive_interval)
          end
          if keepalive_count > 0 && defined?(Socket::TCP_KEEPCNT)
            socket.setsockopt(Socket::IPPROTO_TCP, Socket::TCP_KEEPCNT, keepalive_count)
          end
        end
      else
        path = options[:socket] ||= "/tmp/mysql.sock"
        socket = UNIXSocket.new(path)
      end
    rescue Errno::ETIMEDOUT, IO_TIMEOUT_ERROR => e
      raise Trilogy::TimeoutError, e.message
    rescue SocketError => e
      connection_str = host ? "#{host}:#{port}" : path
      raise Trilogy::BaseConnectionError, "unable to connect to \"#{connection_str}\": #{e.message}"
    rescue => e
      if e.respond_to?(:errno)
        raise Trilogy::SyscallError.from_errno(e.errno, e.message)
      else
        raise
      end
    end

    _connect(socket, encoding, charset, options)
  ensure
    # Socket's fd will be dup'd in C
    socket&.close
  end

  def connection_options
    @connection_options.dup.freeze
  end

  def in_transaction?
    (server_status & SERVER_STATUS_IN_TRANS) != 0
  end

  def server_info
    version_str = server_version

    if /\A(\d+)\.(\d+)\.(\d+)/ =~ version_str
      version_num = ($1.to_i * 10000) + ($2.to_i * 100) + $3.to_i
    end

    { :version => version_str, :id => version_num }
  end

  def connected_host
    @connected_host ||= query_with_flags("select @@hostname", query_flags | QUERY_FLAGS_FLATTEN_ROWS).rows.first
  end

  def query_with_flags(sql, flags)
    old_flags = query_flags
    self.query_flags = flags

    query(sql)
  ensure
    self.query_flags = old_flags
  end
end
