
# -*- ruby -*-
# frozen_string_literal: true

# The top-level PG namespace.
module PG

  # Is this file part of a fat binary gem with bundled libpq?
  # This path must be enabled by add_dll_directory on Windows.
  gplat = Gem::Platform.local
  bundled_libpq_path = Dir[File.expand_path("../ports/#{gplat.cpu}-#{gplat.os}*/lib", __dir__)].first
  if bundled_libpq_path
    POSTGRESQL_LIB_PATH = bundled_libpq_path
  else
    # Try to load libpq path as found by extconf.rb
    begin
      require "pg/postgresql_lib_path"
    rescue LoadError
      # rake-compiler doesn't use regular "make install", but uses it's own install tasks.
      # It therefore doesn't copy pg/postgresql_lib_path.rb in case of "rake compile".
      POSTGRESQL_LIB_PATH = false
    end
  end
  POSTGRESQL_LIB_PATH.freeze

  add_dll_path = proc do |path, &block|
    if RUBY_PLATFORM =~/(mswin|mingw)/i && path
      BUNDLED_LIBPQ_WITH_UNIXSOCKET = false
      begin
        require 'ruby_installer/runtime'
        RubyInstaller::Runtime.add_dll_directory(path, &block)
      rescue LoadError
        old_path = ENV['PATH']
        ENV['PATH'] = "#{path};#{old_path}"
        block.call
        ENV['PATH'] = old_path
      end
    else
      # libpq is found by a relative rpath in the cross compiled extension dll
      # or by the system library loader
      block.call
      BUNDLED_LIBPQ_WITH_UNIXSOCKET = RUBY_PLATFORM=~/linux/i && PG::IS_BINARY_GEM
    end
  end

  # Add a load path to the one retrieved from pg_config
  add_dll_path.call(POSTGRESQL_LIB_PATH) do
    begin
      # Try the <major>.<minor> subdirectory for fat binary gems
      major_minor = RUBY_VERSION[ /^(\d+\.\d+)/ ] or
        raise "Oops, can't extract the major/minor version from #{RUBY_VERSION.dump}"
      require "#{major_minor}/pg_ext"
    rescue LoadError => error1
      begin
        require 'pg_ext'
      rescue LoadError => error2
        msg = <<~EOT
          pg's C extension failed to load:
            #{error1}
            #{error2}
        EOT
        if msg =~ /GLIBC/
          msg += <<~EOT

            The GLIBC version of this system seems too old. Please use the source version of pg:
                gem uninstall pg --all
                gem install pg --platform ruby
            or in your Gemfile:
                gem "pg", force_ruby_platform: true
            See also: https://deveiate.org/code/pg/README_md.html#label-Source+gem
          EOT
        end
        raise error2, msg
      end
    end
  end

  # Get the PG library version.
  #
  # +include_buildnum+ is no longer used and any value passed will be ignored.
  def self.version_string( include_buildnum=nil )
    "%s %s" % [ self.name, VERSION ]
  end


  ### Convenience alias for PG::Connection.new.
  def self.connect( *args, &block )
    Connection.new( *args, &block )
  end

  if defined?(Ractor.make_shareable)
    def self.make_shareable(obj)
      Ractor.make_shareable(obj)
    end
  else
    def self.make_shareable(obj)
      obj.freeze
    end
  end

  module BinaryDecoder
    %i[ TimestampUtc TimestampUtcToLocal TimestampLocal ].each do |klass|
      autoload klass, 'pg/binary_decoder/timestamp'
    end
    autoload :Date, 'pg/binary_decoder/date'
  end
  module BinaryEncoder
    %i[ TimestampUtc TimestampLocal ].each do |klass|
      autoload klass, 'pg/binary_encoder/timestamp'
    end
  end
  module TextDecoder
    %i[ TimestampUtc TimestampUtcToLocal TimestampLocal TimestampWithoutTimeZone TimestampWithTimeZone ].each do |klass|
      autoload klass, 'pg/text_decoder/timestamp'
    end
    autoload :Date, 'pg/text_decoder/date'
    autoload :Inet, 'pg/text_decoder/inet'
    autoload :JSON, 'pg/text_decoder/json'
    autoload :Numeric, 'pg/text_decoder/numeric'
  end
  module TextEncoder
    %i[ TimestampUtc TimestampWithoutTimeZone TimestampWithTimeZone ].each do |klass|
      autoload klass, 'pg/text_encoder/timestamp'
    end
    autoload :Date, 'pg/text_encoder/date'
    autoload :Inet, 'pg/text_encoder/inet'
    autoload :JSON, 'pg/text_encoder/json'
    autoload :Numeric, 'pg/text_encoder/numeric'
  end

  autoload :BasicTypeMapBasedOnResult, 'pg/basic_type_map_based_on_result'
  autoload :BasicTypeMapForQueries, 'pg/basic_type_map_for_queries'
  autoload :BasicTypeMapForResults, 'pg/basic_type_map_for_results'
  autoload :BasicTypeRegistry, 'pg/basic_type_registry'
  require 'pg/exceptions'
  require 'pg/coder'
  require 'pg/type_map_by_column'
  require 'pg/connection'
  require 'pg/cancel_connection'
  require 'pg/result'
  require 'pg/tuple'
  autoload :VERSION, 'pg/version'


  # Avoid "uninitialized constant Truffle::WarningOperations" on Truffleruby up to 22.3.1
  if RUBY_ENGINE=="truffleruby" && !defined?(Truffle::WarningOperations)
    module TruffleFixWarn
      def warn(str, category=nil)
        super(str)
      end
    end
    Warning.extend(TruffleFixWarn)
  end

  # Ruby-3.4+ prints a warning, if bigdecimal is required but not in the Gemfile.
  # But it's a false positive, since we enable bigdecimal depending features only if it's available.
  # And most people don't need these features.
  def self.require_bigdecimal_without_warning
    oldverb, $VERBOSE = $VERBOSE, nil
    require "bigdecimal"
  ensure
    $VERBOSE = oldverb
  end

end # module PG
