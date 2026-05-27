# frozen_string_literal: true

require_relative "config/attr_accessors"
require_relative "config/attr_inheritance"
require_relative "config/attr_type_coercion"
require_relative "config/attr_version_defaults"

module Net
  class IMAP

    # Net::IMAP::Config <em>(available since +v0.4.13+)</em> stores
    # configuration options for Net::IMAP clients.  The global configuration can
    # be seen at either Net::IMAP.config or Net::IMAP::Config.global, and the
    # client-specific configuration can be seen at Net::IMAP#config.
    #
    # When creating a new client, all unhandled keyword arguments to
    # Net::IMAP.new are delegated to Config.new.  Every client has its own
    # config.
    #
    #   debug_client = Net::IMAP.new(hostname, debug: true)
    #   quiet_client = Net::IMAP.new(hostname, debug: false)
    #   debug_client.config.debug?  # => true
    #   quiet_client.config.debug?  # => false
    #
    # == Inheritance
    #
    # Configs have a parent[rdoc-ref:Config::AttrInheritance#parent] config, and
    # any attributes which have not been set locally will inherit the parent's
    # value.  Every client creates its own specific config.  By default, client
    # configs inherit from Config.global.
    #
    #   plain_client = Net::IMAP.new(hostname)
    #   debug_client = Net::IMAP.new(hostname, debug: true)
    #   quiet_client = Net::IMAP.new(hostname, debug: false)
    #
    #   plain_client.config.inherited?(:debug)  # => true
    #   debug_client.config.inherited?(:debug)  # => false
    #   quiet_client.config.inherited?(:debug)  # => false
    #
    #   plain_client.config.debug?  # => false
    #   debug_client.config.debug?  # => true
    #   quiet_client.config.debug?  # => false
    #
    #   # Net::IMAP.debug is delegated to Net::IMAP::Config.global.debug
    #   Net::IMAP.debug = true
    #   plain_client.config.debug?  # => true
    #   debug_client.config.debug?  # => true
    #   quiet_client.config.debug?  # => false
    #
    #   Net::IMAP.debug = false
    #   plain_client.config.debug = true
    #   plain_client.config.inherited?(:debug)  # => false
    #   plain_client.config.debug?  # => true
    #   plain_client.config.reset(:debug)
    #   plain_client.config.inherited?(:debug)  # => true
    #   plain_client.config.debug?  # => false
    #
    # == Versioned defaults
    #
    # The effective default configuration for a specific +x.y+ version of
    # +net-imap+ can be loaded with the +config+ keyword argument to
    # Net::IMAP.new.  Requesting default configurations for previous versions
    # enables extra backward compatibility with those versions:
    #
    #   client = Net::IMAP.new(hostname, config: 0.3)
    #   client.config.sasl_ir                  # => false
    #   client.config.responses_without_block  # => :silence_deprecation_warning
    #
    #   client = Net::IMAP.new(hostname, config: 0.4)
    #   client.config.sasl_ir                  # => true
    #   client.config.responses_without_block  # => :silence_deprecation_warning
    #
    #   client = Net::IMAP.new(hostname, config: 0.5)
    #   client.config.sasl_ir                  # => true
    #   client.config.responses_without_block  # => :warn
    #
    #   client = Net::IMAP.new(hostname, config: :future)
    #   client.config.sasl_ir                  # => true
    #   client.config.responses_without_block  # => :frozen_dup
    #
    # The versioned default configs inherit certain specific config options from
    # Config.global, for example #debug:
    #
    #   client = Net::IMAP.new(hostname, config: 0.4)
    #   Net::IMAP.debug = false
    #   client.config.debug?  # => false
    #
    #   Net::IMAP.debug = true
    #   client.config.debug?  # => true
    #
    # Use #load_defaults to globally behave like a specific version:
    #   client = Net::IMAP.new(hostname)
    #   client.config.sasl_ir              # => true
    #   Net::IMAP.config.load_defaults 0.3
    #   client.config.sasl_ir              # => false
    #
    # === Named defaults
    # In addition to +x.y+ version numbers, the following aliases are supported:
    #
    # [+:default+]
    #   An alias for +:current+.
    #
    #   >>>
    #   *NOTE*: This is _not_ the same as Config.default.  It inherits some
    #   attributes from Config.global, for example: #debug.
    # [+:current+]
    #   An alias for the current +x.y+ version's defaults.
    # [+:next+]
    #   The _planned_ config for the next +x.y+ version.
    # [+:future+]
    #   The _planned_ eventual config for some future +x.y+ version.
    #
    # For example, to disable all currently deprecated behavior:
    #   client = Net::IMAP.new(hostname, config: :future)
    #   client.config.response_without_args     # => :frozen_dup
    #   client.responses.frozen?                # => true
    #   client.responses.values.all?(&:frozen?) # => true
    #
    # == Thread Safety
    #
    # *NOTE:* Updates to config objects are not synchronized for thread-safety.
    #
    class Config
      # Array of attribute names that are _not_ loaded by #load_defaults.
      DEFAULT_TO_INHERIT = %i[debug].freeze
      private_constant :DEFAULT_TO_INHERIT

      # The default config, which is hardcoded and frozen.
      def self.default; @default end

      # The global config object.  Also available from Net::IMAP.config.
      def self.global; @global if defined?(@global) end

      # A hash of hard-coded configurations, indexed by version number or name.
      # Values can be accessed with any object that responds to +to_sym+ or
      # +to_r+/+to_f+ with a non-zero number.
      #
      # Config::[] gets named or numbered versions from this hash.
      #
      # For example:
      #     Net::IMAP::Config.version_defaults[0.5] == Net::IMAP::Config[0.5]
      #     Net::IMAP::Config[0.5]       == Net::IMAP::Config[0.5r]     # => true
      #     Net::IMAP::Config["current"] == Net::IMAP::Config[:current] # => true
      #     Net::IMAP::Config["0.5.6"]   == Net::IMAP::Config[0.5r]     # => true
      def self.version_defaults; AttrVersionDefaults.version_defaults end

      # :call-seq:
      #  Net::IMAP::Config[number] -> versioned config
      #  Net::IMAP::Config[symbol] -> named config
      #  Net::IMAP::Config[hash]   -> new frozen config
      #  Net::IMAP::Config[config] -> same config
      #
      # Given a version number, returns the default configuration for the target
      # version.  See Config@Versioned+defaults.
      #
      # Given a version name, returns the default configuration for the target
      # version.  See Config@Named+defaults.
      #
      # Given a Hash, creates a new _frozen_ config which inherits from
      # Config.global.  Use Config.new for an unfrozen config.
      #
      # Given a config, returns that same config.
      def self.[](config)
        if    config.is_a?(Config)         then config
        elsif config.nil? && global.nil?   then nil
        elsif config.respond_to?(:to_hash) then new(global, **config).freeze
        else
          version_defaults[config] or
            case config
            when Numeric
              raise RangeError, "unknown config version: %p" % [config]
            when String, Symbol
              raise KeyError, "unknown config name: %p" % [config]
            else
              raise TypeError, "no implicit conversion of %s to %s" % [
                config.class, Config
              ]
            end
        end
      end

      include AttrAccessors
      include AttrInheritance
      include AttrTypeCoercion
      extend  AttrVersionDefaults

      # The debug mode (boolean).  The default value is +false+.
      #
      # When #debug is +true+:
      # * Data sent to and received from the server will be logged.
      # * ResponseParser will print warnings with extra detail for parse
      #   errors.  _This may include recoverable errors._
      # * ResponseParser makes extra assertions.
      #
      # *NOTE:* Versioned default configs inherit #debug from Config.global, and
      # #load_defaults will not override #debug.
      attr_accessor :debug, type: :boolean, default: false

      # method: debug?
      # :call-seq: debug? -> boolean
      #
      # Alias for #debug

      # Seconds to wait until a connection is opened.
      #
      # Applied separately for establishing TCP connection and starting a TLS
      # connection.
      #
      # If the IMAP object cannot open a connection within this time,
      # it raises a Net::OpenTimeout exception.
      #
      # See Net::IMAP.new and Net::IMAP#starttls.
      #
      # The default value is +30+ seconds.
      attr_accessor :open_timeout, type: Integer, default: 30

      # Seconds to wait until an IDLE response is received, after
      # the client asks to leave the IDLE state.
      #
      # See Net::IMAP#idle and Net::IMAP#idle_done.
      #
      # The default value is +5+ seconds.
      attr_accessor :idle_response_timeout, type: Integer, default: 5

      # Whether to use the +SASL-IR+ extension when the server and \SASL
      # mechanism both support it.  Can be overridden by the +sasl_ir+ keyword
      # parameter to Net::IMAP#authenticate.
      #
      # <em>(Support for +SASL-IR+ was added in +v0.4.0+.)</em>
      #
      # ==== Valid options
      #
      # [+false+ <em>(original behavior, before support was added)</em>]
      #   Do not use +SASL-IR+, even when it is supported by the server and the
      #   mechanism.
      #
      # [+:when_capabilities_cached+]
      #   Use +SASL-IR+ when Net::IMAP#capabilities_cached? is +true+ and it is
      #   supported by the server and the mechanism, but do not send a
      #   +CAPABILITY+ command to discover the server capabilities.
      #
      #   <em>(+:when_capabilities_cached+ option was added by +v0.6.0+)</em>
      #
      # [+true+ <em>(default since +v0.4+)</em>]
      #   Use +SASL-IR+ when it is supported by the server and the mechanism.
      attr_accessor :sasl_ir, type: Enum[
        false, :when_capabilities_cached, true
      ], defaults: {
        0.0r => false,
        0.4r => true,
      }

      # :stopdoc:
      alias sasl_ir? sasl_ir
      # :startdoc:

      # Controls the behavior of Net::IMAP#login when the +LOGINDISABLED+
      # capability is present.  When enforced, Net::IMAP will raise a
      # LoginDisabledError when that capability is present.
      #
      # <em>(Support for +LOGINDISABLED+ was added in +v0.5.0+.)</em>
      #
      # ==== Valid options
      #
      # [+false+ <em>(original behavior, before support was added)</em>]
      #   Send the +LOGIN+ command without checking for +LOGINDISABLED+.
      #
      # [+:when_capabilities_cached+]
      #   Enforce the requirement when Net::IMAP#capabilities_cached? is true,
      #   but do not send a +CAPABILITY+ command to discover the capabilities.
      #
      # [+true+ <em>(default since +v0.5+)</em>]
      #   Only send the +LOGIN+ command if the +LOGINDISABLED+ capability is not
      #   present.  When capabilities are unknown, Net::IMAP will automatically
      #   send a +CAPABILITY+ command first before sending +LOGIN+.
      #
      attr_accessor :enforce_logindisabled, type: Enum[
        false, :when_capabilities_cached, true
      ], defaults: {
        0.0r => false,
        0.5r => true,
      }

      # The maximum bytesize for sending non-synchronizing literals, when the
      # server supports them.  To disable non-synchronizing literals, set the
      # value to +-1+.
      #
      # Non-synchronizing literals are only sent when the server's
      # capabilities[rdoc-ref:IMAP#capabilities] have been
      # cached[rdoc-ref:IMAP#capabilities_cached?] and include either
      # <tt>LITERAL+</tt> [RFC7888[https://www.rfc-editor.org/rfc/rfc7888]],
      # <tt>LITERAL-</tt> [RFC7888[https://www.rfc-editor.org/rfc/rfc7888]], or
      # +IMAP4rev2+ [RFC9051[https://www.rfc-editor.org/rfc/rfc9051]].
      #
      # For <tt>LITERAL+</tt>, this value is the only limit on whether a literal
      # value is sent as non-synchronizing literals.  For <tt>LITERAL-</tt> and
      # <tt>IMAP4rev2</tt>, non-synchronizing literals must also be smaller than
      # +4096+ bytes.
      #
      # Non-synchronizing literals avoid the latency of waiting for the server
      # to allow continuation.  However, if a client sends a non-synchronizing
      # literal that is too large for the server, the server may need to close
      # the connection.  Because <tt>LITERAL+</tt> does not directly indicate
      # the server's limits, it's best to avoid sending very large
      # non-synchronized literals.
      #
      # ==== Versioned Defaults
      #
      # max_non_synchronizing_literal <em>was added in +v0.6.4+.</em>
      #
      # * original: +-1+ (_never_ send non-synchronizing literals)
      # * +0.6+: 16 KiB
      attr_accessor :max_non_synchronizing_literal, type: Integer?, defaults: {
        0.0r => -1,
        0.6r => 16 << 16, # 16 KiB
      }

      # The maximum allowed server response size.  When +nil+, there is no limit
      # on response size.
      #
      # The default value (512 MiB, since +v0.5.7+) is <em>very high</em> and
      # unlikely to be reached.  A _much_ lower value should be used with
      # untrusted servers (for example, when connecting to a user-provided
      # hostname).  When using a lower limit, message bodies should be fetched
      # in chunks rather than all at once.
      #
      # <em>Please Note:</em> this only limits the size per response.  It does
      # not prevent a flood of individual responses and it does not limit how
      # many unhandled responses may be stored on the responses hash.  See
      # Net::IMAP@Unbounded+memory+use.
      #
      # Socket reads are limited to the maximum remaining bytes for the current
      # response: max_response_size minus the bytes that have already been read.
      # When the limit is reached, or reading a +literal+ _would_ go over the
      # limit, ResponseTooLargeError is raised and the connection is closed.
      #
      # Note that changes will not take effect immediately, because the receiver
      # thread may already be waiting for the next response using the previous
      # value.  Net::IMAP#noop can force a response and enforce the new setting
      # immediately.
      #
      # ==== Versioned Defaults
      #
      # Net::IMAP#max_response_size <em>was added in +v0.2.5+ and +v0.3.9+ as an
      # attr_accessor, and in +v0.4.20+ and +v0.5.7+ as a delegator to this
      # config attribute.</em>
      #
      # * original: +nil+ <em>(no limit)</em>
      # * +0.5+: 512 MiB
      attr_accessor :max_response_size, type: Integer?, defaults: {
        0.0r => nil,
        0.5r => 512 << 20, # 512 MiB
      }

      # Controls the behavior of Net::IMAP#responses when called without any
      # arguments (+type+ or +block+).
      #
      # ==== Valid options
      #
      # [+:silence_deprecation_warning+ <em>(original behavior)</em>]
      #   Returns the mutable responses hash (without any warnings).
      #   <em>This is not thread-safe.</em>
      #
      # [+:warn+ <em>(default since +v0.5+)</em>]
      #   Prints a warning and returns the mutable responses hash.
      #   <em>This is not thread-safe.</em>
      #
      # [+:frozen_dup+ <em>(planned default for +v0.6+)</em>]
      #   Returns a frozen copy of the unhandled responses hash, with frozen
      #   array values.
      #
      #   Note that calling IMAP#responses with a +type+ and without a block is
      #   not configurable and always behaves like +:frozen_dup+.
      #
      #   <em>(+:frozen_dup+ config option was added in +v0.4.17+)</em>
      #
      # [+:raise+]
      #   Raise an ArgumentError with the deprecation warning.
      #
      # Note: #responses_without_args is an alias for #responses_without_block.
      attr_accessor :responses_without_block, type: Enum[
        :silence_deprecation_warning, :warn, :frozen_dup, :raise,
      ], defaults: {
        0.0r => :silence_deprecation_warning,
        0.5r => :warn,
        0.6r => :frozen_dup,
      }

      alias responses_without_args  responses_without_block  # :nodoc:
      alias responses_without_args= responses_without_block= # :nodoc:

      ##
      # :attr_accessor: responses_without_args
      #
      # Alias for responses_without_block

      # **NOTE:** <em>+UIDPlusData+ has been removed since +v0.6.0+, and this
      # config option only affects deprecation warnings.
      # This config option will be **removed** in +v0.7.0+.</em>
      #
      # ResponseParser always returns CopyUIDData for +COPYUID+ response codes,
      # and AppendUIDData for +APPENDUID+ response codes.  Previously, this
      # option determined when UIDPlusData would be returned instead.
      #
      # Parser support for +UIDPLUS+ added in +v0.3.2+.
      #
      # Config option added in +v0.4.19+ and +v0.5.6+.
      #
      # <em>UIDPlusData removed in +v0.6.0+.</em>
      #
      # ==== Options
      #
      # [+true+ <em>(original default)</em>]
      #    <em>Since v0.6.0:</em>
      #    Prints a deprecation warning when parsing +COPYUID+ or +APPENDUID+.
      #
      # [+:up_to_max_size+ <em>(default since +v0.5.6+)</em>]
      #    <em>Since v0.6.0:</em>
      #    Prints a deprecation warning when parsing +COPYUID+ or +APPENDUID+.
      #
      # [+false+ <em>(default since +v0.6.0+)</em>]
      #    This is the only supported option <em>(since v0.6.0)</em>.
      attr_accessor :parser_use_deprecated_uidplus_data, type: Enum[
        true, :up_to_max_size, false
      ], defaults: {
        0.0r => true,
        0.5r => :up_to_max_size,
        0.6r => false,
      }

      # **NOTE:** <em>+UIDPlusData+ has been removed since +v0.6.0+, and this
      # config option is ignored.
      # This config option will be **removed** in +v0.7.0+.</em>
      #
      # ResponseParser always returns CopyUIDData for +COPYUID+ response codes,
      # and AppendUIDData for +APPENDUID+ response codes.  Previously, this
      # option determined when UIDPlusData would be returned instead.
      #
      # Parser support for +UIDPLUS+ added in +v0.3.2+.
      #
      # Support for limiting UIDPlusData to a maximum size was added in
      # +v0.3.8+, +v0.4.19+, and +v0.5.6+.
      #
      # <em>UIDPlusData was removed in +v0.6.0+.</em>
      #
      # ==== Versioned Defaults
      #
      # * +0.3+ and prior: <tt>10,000</tt>
      # * +0.4+: <tt>1,000</tt>
      # * +0.5+: <tt>100</tt>
      # * +0.6+: <tt>0</tt>
      #
      attr_accessor :parser_max_deprecated_uidplus_data_size, type: Integer,
        defaults: {
          0.0r => 10_000,
          0.4r =>  1_000,
          0.5r =>    100,
          0.6r =>      0,
        }

      # Creates a new config object and initialize its attribute with +attrs+.
      #
      # If +parent+ is not given, the global config is used by default.
      #
      # If a block is given, the new config object is yielded to it.
      def initialize(parent = Config.global, **attrs)
        super(parent)
        update(**attrs)
        yield self if block_given?
      end

      # :call-seq: update(**attrs) -> self
      #
      # Assigns all of the provided +attrs+ to this config, and returns +self+.
      #
      # An ArgumentError is raised unless every key in +attrs+ matches an
      # assignment method on Config.
      #
      # >>>
      #   *NOTE:*  #update is not atomic.  If an exception is raised due to an
      #   invalid attribute value, +attrs+ may be partially applied.
      def update(**attrs)
        unless (bad = attrs.keys.reject { respond_to?(:"#{_1}=") }).empty?
          raise ArgumentError, "invalid config options: #{bad.join(", ")}"
        end
        attrs.each do send(:"#{_1}=", _2) end
        self
      end

      # :call-seq:
      #   with(**attrs) -> config
      #   with(**attrs) {|config| } -> result
      #
      # Without a block, returns a new config which inherits from self.  With a
      # block, yields the new config and returns the block's result.
      #
      # If no keyword arguments are given, an ArgumentError will be raised.
      #
      # If +self+ is frozen, the copy will also be frozen.
      def with(**attrs)
        attrs.empty? and
          raise ArgumentError, "expected keyword arguments, none given"
        copy = new(**attrs)
        copy.freeze if frozen?
        block_given? ? yield(copy) : copy
      end

      # :call-seq: load_defaults(version) -> self
      #
      # Resets the current config to behave like the versioned default
      # configuration for +version+.  #parent will not be changed.
      #
      # Some config attributes default to inheriting from their #parent (which
      # is usually Config.global) and are left unchanged, for example: #debug.
      #
      # See Config@Versioned+defaults and Config@Named+defaults.
      def load_defaults(version)
        [Numeric, Symbol, String].any? { _1 === version } or
          raise ArgumentError, "expected number or symbol, got %p" % [version]
        update(**Config[version].defaults_hash)
      end

      # :call-seq: to_h -> hash
      #
      # Returns all config attributes in a hash.
      def to_h; data.members.to_h { [_1, send(_1)] } end

      # Returns a string representation of overriden config attributes and the
      # inheritance chain.
      #
      # Attributes overridden by ancestors are also inspected, recursively.
      # Attributes that are inherited from default configs are not shown (see
      # Config@Versioned+defaults and Config@Named+defaults).
      #
      #     # (Line breaks have been added to the example output for legibility.)
      #
      #     Net::IMAP::Config.new(0.4)
      #       .new(open_timeout: 10, enforce_logindisabled: true)
      #       .inspect
      #     #=> "#<Net::IMAP::Config:0x0000745871125410 open_timeout=10 enforce_logindisabled=true
      #     #      inherits from Net::IMAP::Config[0.4]
      #     #      inherits from Net::IMAP::Config.global
      #     #      inherits from Net::IMAP::Config.default>"
      #
      # Non-default attributes are listed after the ancestor config from which
      # they are inherited.
      #
      #     # (Line breaks have been added to the example output for legibility.)
      #
      #     config = Net::IMAP::Config.global
      #       .new(open_timeout: 10, idle_response_timeout: 2)
      #       .new(enforce_logindisabled: :when_capabilities_cached, sasl_ir: false)
      #     config.inspect
      #     #=> "#<Net::IMAP::Config:0x00007ce2a1e20e40 sasl_ir=false enforce_logindisabled=:when_capabilities_cached
      #     #      inherits from Net::IMAP::Config:0x00007ce2a1e20f80 open_timeout=10 idle_response_timeout=2
      #     #      inherits from Net::IMAP::Config.global
      #     #      inherits from Net::IMAP::Config.default>"
      #
      #     Net::IMAP.debug = true
      #     config.inspect
      #     #=> "#<Net::IMAP::Config:0x00007ce2a1e20e40 sasl_ir=false enforce_logindisabled=:when_capabilities_cached
      #     #      inherits from Net::IMAP::Config:0x00007ce2a1e20f80 open_timeout=10 idle_response_timeout=2
      #     #      inherits from Net::IMAP::Config.global debug=true
      #     #      inherits from Net::IMAP::Config.default>"
      #
      # Use +pp+ (see #pretty_print) to inspect _all_ config attributes,
      # including default values.
      #
      # Use #to_h to inspect all config attributes ignoring inheritance.
      def inspect;
        "#<#{inspect_recursive}>"
      end
      alias to_s inspect

      # Used by PP[https://docs.ruby-lang.org/en/master/PP.html] to create a
      # string representation of all config attributes and the inheritance
      # chain.  Inherited attributes are listed with the ancestor config from
      # which they are inherited.
      #
      #     pp Config.new[0.4].new(open_timeout: 10, idle_response_timeout: 10)
      #     # #<Net::IMAP::Config:0x0000745871125410
      #     #   open_timeout=10
      #     #   idle_response_timeout=10
      #     #   inherits from Net::IMAP::Config[0.4]
      #     #     responses_without_block=:silence_deprecation_warning
      #     #     max_response_size=nil
      #     #     sasl_ir=true
      #     #     enforce_logindisabled=false
      #     #     parser_use_deprecated_uidplus_data=true
      #     #     parser_max_deprecated_uidplus_data_size=1000
      #     #     inherits from Net::IMAP::Config.global
      #     #       inherits from Net::IMAP::Config.default
      #     #         debug=false>
      #
      # Related: #inspect, #to_h.
      def pretty_print(pp)
        pp.group(2, "#<", ">") do
          pretty_print_recursive(pp)
        end
      end

      # :stopdoc:

      protected

      def named_default?
        equal?(Config.default) ||
          AttrVersionDefaults::VERSIONS.any? { equal? Config[_1] }
      end

      def name
        if    equal? Config.default   then "#{Config}.default"
        elsif equal? Config.global    then "#{Config}.global"
        elsif equal? Config[0.0r]     then "#{Config}[:original]"
        elsif (v = AttrVersionDefaults::VERSIONS.find { equal? Config[_1] })
          "%s[%0.1f]" % [Config, v]
        else
          Kernel.instance_method(:to_s).bind_call(self).delete("<#>")
        end
      end

      def inspect_recursive(attrs = AttrAccessors.struct.members)
        strings  = [name]
        assigned = assigned_attrs_hash(attrs)
        strings.concat assigned.map { "%s=%p" % _1 }
        if parent
          if parent.equal?(Config.default)
            inherited_overrides = []
          elsif parent
            inherited_overrides = attrs - assigned.keys
            inherited_overrides &= DEFAULT_TO_INHERIT if parent.named_default?
          end
          strings << "inherits from #{parent.inspect_recursive(inherited_overrides)}"
        end
        strings.join " "
      end

      def pretty_print_recursive(pp, attrs = AttrAccessors.struct.members)
        pp.text name
        assigned = assigned_attrs_hash(attrs)
        pp.breakable
        pp.seplist(assigned, ->{pp.breakable}) do |key, val|
          pp.text key.to_s
          pp.text "="
          pp.pp val
        end
        if parent
          pp.breakable if assigned.any?
          pp.nest(2) do
            pp.text "inherits from "
            parent.pretty_print_recursive(pp, attrs - assigned.keys)
          end
        elsif assigned.empty?
          pp.text "(overridden)"
        end
      end

      def assigned_attrs_hash(attrs)
        own_attrs = attrs.reject { inherited?(_1) }
        own_attrs.to_h { [_1, data[_1]] }
      end

      def defaults_hash
        to_h.reject {|k,v| DEFAULT_TO_INHERIT.include?(k) }
      end

      Struct   = AttrAccessors.struct
      @default = AttrVersionDefaults.compile_default!
      @global  = default.new
      AttrVersionDefaults.compile_version_defaults!

    end
  end
end
