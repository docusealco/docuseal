# frozen_string_literal: true

require "forwardable"

module Net
  class IMAP
    class Config
      # >>>
      #   *NOTE:* This module is an internal implementation detail, with no
      #   guarantee of backward compatibility.
      #
      # Adds a +defaults+ parameter to +attr_accessor+, which is used to compile
      # Config.version_defaults.
      module AttrVersionDefaults
        # The <tt>x.y</tt> part of Net::IMAP::VERSION, as a Rational number.
        CURRENT_VERSION = VERSION.to_r

        # The config version used for <tt>Config[:next]</tt>.
        NEXT_VERSION    = CURRENT_VERSION + 0.1r

        # The config version used for <tt>Config[:future]</tt>.
        FUTURE_VERSION  = 1.0r

        VERSIONS = ((0.0r..FUTURE_VERSION) % 0.1r).to_a.freeze

        # See Config.version_defaults.
        singleton_class.attr_reader :version_defaults

        @version_defaults = Hash.new {|h, k|
          # NOTE: String responds to both so the order is significant.
          # And ignore non-numeric conversion to zero, because: "wat!?".to_r == 0
          (h.fetch(k.to_r, nil) || h.fetch(k.to_f, nil) if k.is_a?(Numeric)) ||
            (h.fetch(k.to_sym, nil) if k.respond_to?(:to_sym)) ||
            (h.fetch(k.to_r,   nil) if k.respond_to?(:to_r) && k.to_r != 0r) ||
            (h.fetch(k.to_f,   nil) if k.respond_to?(:to_f) && k.to_f != 0.0)
        }

        # :stopdoc: internal APIs only

        def attr_accessor(name, defaults: nil, default: (unset = true), **kw)
          unless unset
            version  = DEFAULT_TO_INHERIT.include?(name) ? nil : 0.0r
            defaults = { version => default }
          end
          defaults&.each_pair do |version, default|
            AttrVersionDefaults.version_defaults[version] ||= {}
            AttrVersionDefaults.version_defaults[version][name] = default
          end
          super(name, **kw)
        end

        def self.compile_default!
          raise "Config.default already compiled" if Config.default
          default = VERSIONS.select { _1 <= CURRENT_VERSION }
            .filter_map { version_defaults[_1] }
            .prepend(version_defaults.delete(nil))
            .inject(&:merge)
          Config.new(**default).freeze
        end

        def self.compile_version_defaults!
          version_defaults[0.0r]     = Config[version_defaults.fetch(0.0r)]

          VERSIONS.each_cons(2) do |prior, version|
            updates = version_defaults[version]
            version_defaults[version] = version_defaults[prior]
              .then { updates ? _1.dup.update(**updates).freeze : _1 }
          end

          # Safe conversions one way only:
          #   0.6r.to_f == 0.6  # => true
          #   0.6 .to_r == 0.6r # => false
          version_defaults.to_a.each do |k, v|
            next unless k in Rational
            version_defaults[k.to_f] = v
          end

          version_defaults[:original] = Config[0.0r]
          version_defaults[:current]  = Config[CURRENT_VERSION]
          version_defaults[:default]  = Config[CURRENT_VERSION]
          version_defaults[:next]     = Config[NEXT_VERSION]
          version_defaults[:future]   = Config[FUTURE_VERSION]

          version_defaults.freeze
        end

      end
    end
  end
end
