# frozen_string_literal: true

module Net
  class IMAP < Protocol

    # Superclass of IMAP errors.
    class Error < StandardError
    end

    class LoginDisabledError < Error
      def initialize(msg = "Remote server has disabled the LOGIN command", ...)
        super
      end
    end

    # Error raised when data is in the incorrect format.
    class DataFormatError < Error
    end

    # Error raised when the socket cannot be read, due to a Config limit.
    class ResponseReadError < Error
    end

    # Error raised when a response is larger than IMAP#max_response_size.
    class ResponseTooLargeError < ResponseReadError
      attr_reader :bytes_read, :literal_size
      attr_reader :max_response_size

      def initialize(msg = nil, *args,
                     bytes_read:        nil,
                     literal_size:      nil,
                     max_response_size: nil,
                     **kwargs)
        @bytes_read        = bytes_read
        @literal_size      = literal_size
        @max_response_size = max_response_size
        msg ||= [
          "Response size", response_size_msg, "exceeds max_response_size",
          max_response_size && "(#{max_response_size}B)",
        ].compact.join(" ")
        super(msg, *args, **kwargs)
      end

      private

      def response_size_msg
        if bytes_read && literal_size
          "(#{bytes_read}B read + #{literal_size}B literal)"
        end
      end
    end

    # Error raised when a response from the server is non-parsable.
    #
    # NOTE: Parser attributes are provided for debugging and inspection only.
    # Their names and semantics may change incompatibly in any release.
    class ResponseParseError < Error
      # returns "" for all highlights
      ESC_NO_HL = Hash.new("").freeze
      private_constant :ESC_NO_HL

      # Translates hash[:"/foo"] to hash[:reset] when hash.key?(:foo), else ""
      #
      # TODO: DRY this up with Config::AttrTypeCoercion.safe
      if defined?(::Ractor.shareable_proc)
        default_highlight = Ractor.shareable_proc {|hash, key|
          %r{\A/(.+)} =~ key && hash.key?($1.to_sym) ? hash[:reset] : ""
        }
      else
        default_highlight = nil.instance_eval { Proc.new {|hash, key|
          %r{\A/(.+)} =~ key && hash.key?($1.to_sym) ? hash[:reset] : ""
        } }
        ::Ractor.make_shareable(default_highlight) if defined?(::Ractor)
      end

      # ANSI highlights, but no colors
      ESC_NO_COLOR = Hash.new(&default_highlight).update(
        reset: "\e[m",
        val:   "\e[1m",   # bold
        alt:   "\e[1;4m", # bold and underlined
        sym:   "\e[1m",   # bold
        label: "\e[1m",   # bold
      ).freeze
      private_constant :ESC_NO_COLOR

      # ANSI highlights, with color
      ESC_COLORS = Hash.new(&default_highlight).update(
        reset: "\e[m",
        key:   "\e[95m",      # bright magenta
        idx:   "\e[34m",      # blue
        val:   "\e[36;40m",   # cyan on black (to ensure contrast)
        alt:   "\e[1;33;40m", # bold; yellow on black
        sym:   "\e[33;40m",   # yellow on black
        label: "\e[1m",       # bold
        nil:   "\e[35m",      # magenta
      ).freeze
      private_constant :ESC_COLORS

      # Net::IMAP::ResponseParser, unless a custom parser produced the error.
      attr_reader :parser_class

      # The full raw response string which was being parsed.
      attr_reader :string

      # The parser's byte position in #string when the error was raised.
      #
      # _NOTE:_ This attribute is provided for debugging and inspection only.
      # Its name and semantics may change incompatibly in any release.
      attr_reader :pos

      # The parser's lex state
      #
      # _NOTE:_ This attribute is provided for debugging and inspection only.
      # Its name and semantics may change incompatibly in any release.
      attr_reader :lex_state

      # The last lexed token
      #
      # May be +nil+ when the parser has accepted the last token and peeked at
      # the next byte without generating a token.
      #
      # _NOTE:_ This attribute is provided for debugging and inspection only.
      # Its name and semantics may change incompatibly in any release.
      attr_reader :token

      def initialize(message = "unspecified parse error",
                     parser_class: Net::IMAP::ResponseParser,
                     parser_state: nil,
                     string:    parser_state&.at(0), # see ParserUtils#parser_state
                     lex_state: parser_state&.at(1), # see ParserUtils#parser_state
                     pos:       parser_state&.at(2), # see ParserUtils#parser_state
                     token:     parser_state&.at(3)) # see ParserUtils#parser_state
        @parser_class = parser_class
        @string    = string
        @pos       = pos
        @lex_state = lex_state
        @token     = token
        super(message)
      end

      # When +parser_state+ is true, debug info about the parser state is
      # included.  Defaults to the value of Net::IMAP.debug.
      #
      # When +parser_backtrace+ is true, a simplified backtrace is included,
      # containing only frames for methods in parser_class (since ruby 3.4) or
      # which have "net/imap/response_parser" in the path (before ruby 3.4).
      # Most parser method names are based on rules in the IMAP grammar.
      #
      # When +highlight+ is not explicitly set, highlights may be enabled
      # automatically, based on +TERM+ and +FORCE_COLOR+ environment variables.
      #
      # By default, +highlight+ uses colors from the basic ANSI palette.  When
      # +highlight_no_color+ is true or the +NO_COLOR+ environment variable is
      # not empty, only monochromatic highlights are used: bold, underline, etc.
      def detailed_message(parser_state: Net::IMAP.debug,
                           parser_backtrace: false,
                           highlight: default_highlight_from_env,
                           highlight_no_color: (ENV["NO_COLOR"] || "") != "",
                           **)
        return super unless parser_state || parser_backtrace
        msg = super.dup
        esc = !highlight ? ESC_NO_HL : highlight_no_color ? ESC_NO_COLOR : ESC_COLORS
        hl  = ->str { str % esc }
        val = ->str, val { hl[val.nil? ? "%{nil}%%p%{/nil}" : str] % val }
        if parser_state && (string || pos || lex_state || token)
          msg << hl["\n  %{key}processed %{/key}: "] << val["%{val}%%p%{/val}", processed_string]
          msg << hl["\n  %{key}remaining %{/key}: "] << val["%{alt}%%p%{/alt}", remaining_string]
          msg << hl["\n  %{key}pos       %{/key}: "] << val["%{val}%%p%{/val}", pos]
          msg << hl["\n  %{key}lex_state %{/key}: "] << val["%{sym}%%p%{/sym}", lex_state]
          msg << hl["\n  %{key}token     %{/key}: "] << val[
            "%{sym}%%<symbol>p%{/sym} => %{val}%%<value>p%{/val}", token&.to_h
          ]
        end
        if parser_backtrace
          normalized_parser_backtrace.each do |idx, path, lineno, label, base_label|
            msg << "\n  %s: %s (%s:%d)" % [
              hl["%{key}caller[%{/key}%{idx}%%2d%{/idx}%{key}]%{/key}"] % idx,
              hl["%{label}%%-30s%{/label}"] % base_label,
              File.basename(path, ".rb"), lineno
            ]
          end
        end
        msg
      rescue => error
        msg ||= super.dup
        msg << "\n  BUG in %s#%s: %s" % [self.class, __method__,
                                         error.detailed_message]
        msg
      end

      def processed_string = string && pos && string[...pos]
      def remaining_string = string && pos && string[pos..]

      # Returns true when all attributes are equal, except for #backtrace and
      # #backtrace_locations which are replaced with #parser_methods.  This
      # allows deserialized errors to be compared.
      def ==(other)
        return false if self.class != other.class
        methods       = parser_methods
        other_methods = other.parser_methods
        message     == other.message &&
          methods   == other_methods &&
          string    == other.string &&
          pos       == other.pos &&
          lex_state == other.lex_state &&
          token     == other.token
      end

      # Lists the methods (from #backtrace_locations or #backtrace) called on
      # parser_class (since ruby 3.4) or which have "net/imap/response_parser"
      # in the path (before ruby 3.4).  Most parser method names are based on
      # rules in the IMAP grammar.
      def parser_methods = normalized_parser_backtrace.map(&:last)

      private

      def normalized_parser_backtrace
        normalize_backtrace
          .take_while {|_, _, _, _, base_label| base_label != "parse" }
          .reject {|_, _, _, _, base_label| base_label.nil? }
          .reject {|_, _, _, _, base_label| base_label.include? "parse_error" }
          .select {|_, path, _, label, _|
            if label.include?("#") # => Class#method, since ruby 3.4
              label.include?(parser_class.name)
            else
              path.include?("net/imap/response_parser")
            end
          }
      end

      def normalize_backtrace
        (backtrace_locations&.each_with_index&.map {|loc, idx|
          [idx, loc.path, loc.lineno, loc.label, loc.base_label]
        } || backtrace&.each_with_index&.map {|bt, idx|
          [idx, *bt.match(/\A(\S+):(\d+):in [`'](.*?([\w]+[?!]?))'\z/)&.captures]
        } || [])
      end

      def default_highlight_from_env
        (ENV["FORCE_COLOR"] || "") !~ /\A(?:0|)\z/ ||
          (ENV["TERM"] || "") !~ /\A(?:dumb|unknown|)\z/i
      end

    end

    # Superclass of all errors used to encapsulate "fail" responses
    # from the server.
    class ResponseError < Error

      # The response that caused this error
      attr_accessor :response

      def initialize(response)
        @response = response

        super @response.data.text
      end

    end

    # Error raised upon a "NO" response from the server, indicating
    # that the client command could not be completed successfully.
    class NoResponseError < ResponseError
    end

    # Error raised upon a "BAD" response from the server, indicating
    # that the client command violated the IMAP protocol, or an internal
    # server failure has occurred.
    class BadResponseError < ResponseError
    end

    # Error raised upon a "BYE" response from the server, indicating
    # that the client is not being allowed to login, or has been timed
    # out due to inactivity.
    class ByeResponseError < ResponseError
    end

    # Error raised when the server sends an invalid response.
    #
    # This is different from UnknownResponseError: the response has been
    # rejected.  Although it may be parsable, the server is forbidden from
    # sending it in the current context.  The client should automatically
    # disconnect, abruptly (without logout).
    #
    # Note that InvalidResponseError does not inherit from ResponseError: it
    # can be raised before the response is fully parsed.  A related
    # ResponseParseError or ResponseError may be the #cause.
    class InvalidResponseError < Error
    end

    # Error raised upon an unknown response from the server.
    #
    # This is different from InvalidResponseError: the response may be a
    # valid extension response and the server may be allowed to send it in
    # this context, but Net::IMAP either does not know how to parse it or
    # how to handle it.  This could result from enabling unknown or
    # unhandled extensions.  The connection may still be usable,
    # but—depending on context—it may be prudent to disconnect.
    class UnknownResponseError < ResponseError
    end

    RESPONSE_ERRORS = Hash.new(ResponseError) # :nodoc:
    RESPONSE_ERRORS["NO"] = NoResponseError
    RESPONSE_ERRORS["BAD"] = BadResponseError

  end
end
