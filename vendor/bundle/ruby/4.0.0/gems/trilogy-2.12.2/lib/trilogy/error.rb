class Trilogy
  # Trilogy::Error is the base error type. All errors raised by Trilogy
  # should be descendants of Trilogy::Error
  module Error
    attr_reader :error_code
  end

  # Trilogy::ConnectionError is the base error type for all potentially transient
  # network errors.
  module ConnectionError
    include Error
  end

  # Trilogy may raise various syscall errors, which we treat as Trilogy::Errors.
  module SyscallError
    ERRORS = {}

    Errno.constants
      .map { |c| Errno.const_get(c) }.uniq
      .select { |c| c.is_a?(Class) && c < SystemCallError }
      .each do |c|
        errno_name = c.to_s.split('::').last
        ERRORS[c::Errno] = const_set(errno_name, Class.new(c) {
          include Trilogy::ConnectionError
          singleton_class.define_method(:===, Module.instance_method(:===))
        })
      end

    ERRORS.freeze

    class << self
      def from_errno(errno, message)
        ERRORS[errno].new(message)
      end
    end
  end

  ConnectionRefusedError = SyscallError::ECONNREFUSED
  deprecate_constant :ConnectionRefusedError
  ConnectionResetError = SyscallError::ECONNRESET
  deprecate_constant :ConnectionResetError

  class BaseError < StandardError
    include Error

    def initialize(error_message = nil, error_code = nil)
      message = error_code ? "#{error_code}: #{error_message}" : error_message
      super(message)
      @error_code = error_code
    end
  end

  class BaseConnectionError < BaseError
    include ConnectionError
  end

  class SynchronizationError < BaseError
    def initialize(message = "This connection is already in use by another thread or fiber")
      super
    end
  end

  # Trilogy::ClientError is the base error type for invalid queries or parameters
  # that shouldn't be retried.
  class ClientError < BaseError
    include Error
  end

  class QueryError < ClientError
  end

  class CastError < ClientError
  end

  class TimeoutError < BaseConnectionError
  end

  # DatabaseError was replaced by ProtocolError, but we'll keep it around as an
  # ancestor of ProtocolError for compatibility reasons (e.g. so `rescue DatabaseError`
  # still works. We can remove this class in the next major release.
  module DatabaseError
  end

  class ProtocolError < BaseError
    include DatabaseError

    ERROR_CODES = {
      1205 => TimeoutError, # ER_LOCK_WAIT_TIMEOUT
      1044 => BaseConnectionError, # ER_DBACCESS_DENIED_ERROR
      1045 => BaseConnectionError, # ER_ACCESS_DENIED_ERROR
      1064 => QueryError, # ER_PARSE_ERROR
      1152 => BaseConnectionError, # ER_ABORTING_CONNECTION
      1153 => BaseConnectionError, # ER_NET_PACKET_TOO_LARGE
      1154 => BaseConnectionError, # ER_NET_READ_ERROR_FROM_PIPE
      1155 => BaseConnectionError, # ER_NET_FCNTL_ERROR
      1156 => BaseConnectionError, # ER_NET_PACKETS_OUT_OF_ORDER
      1157 => BaseConnectionError, # ER_NET_UNCOMPRESS_ERROR
      1158 => BaseConnectionError, # ER_NET_READ_ERROR
      1159 => BaseConnectionError, # ER_NET_READ_INTERRUPTED
      1160 => BaseConnectionError, # ER_NET_ERROR_ON_WRITE
      1161 => BaseConnectionError, # ER_NET_WRITE_INTERRUPTED
      1927 => BaseConnectionError, # ER_CONNECTION_KILLED
      4031 => BaseConnectionError, # Disconnected by server
    }
    class << self
      def from_code(message, code)
        ERROR_CODES.fetch(code, self).new(message, code)
      end
    end
  end

  class SSLError < BaseError
    include ConnectionError
  end

  # Raised on attempt to use connection which was explicitly closed by the user
  class ConnectionClosed < IOError
    include ConnectionError
  end

  # Occurs when a socket read or write returns EOF or when an operation is
  # attempted on a socket which previously encountered an error.
  class EOFError < BaseConnectionError
  end

  # Occurs when the server request an auth switch to an incompatible
  # authentication plugin
  class AuthPluginError < Trilogy::BaseConnectionError
  end
end
