$LOAD_PATH.unshift "test", "lib"

require "simplecov" if ENV["MT_COV"] || ARGV.delete("--simplecov")
require_relative "autorun"
require_relative "path_expander"

module Minitest

  ##
  # Runs (Get it? It's fast!) your tests and makes it easier to rerun
  # individual failures.

  class Sprint
    # extracted version = "1.5.0"

    ##
    # Process and run minitest cmdline.

    def self.run args = ARGV
      if args.delete("--bisect") or args.delete("-b") then
        require_relative "bisect"

        return Minitest::Bisect.run ARGV
      end

      Minitest::PathExpander.new(args).process { |f|
        require "./#{f}" if File.file? f
      }
    end

    ##
    # An extra minitest reporter to output how to rerun failures in
    # various styles.

    class SprintReporter < AbstractReporter
      ##
      # The style to report, either lines or regexp. Defaults to lines.
      attr_accessor :style
      attr_accessor :results # :nodoc:

      def initialize style = :regexp # :nodoc:
        self.results = []
        self.style = style
      end

      def record result # :nodoc:
        results << result unless result.passed? or result.skipped?
      end

      def report # :nodoc:
        return if results.empty?

        puts
        puts "Happy Happy Sprint List:"
        puts
        print_list
        puts
      end

      def print_list # :nodoc:
        case style
        when :regexp
          results.each do |result|
            puts "  minitest -n #{result.class_name}##{result.name}"
          end
        when :lines
          files = Hash.new { |h,k| h[k] = [] }
          results.each do |result|
            path, line = result.source_location
            path = path.delete_prefix "#{Dir.pwd}/"
            files[path] << line
          end

          files.sort.each do |path, lines|
            puts "  minitest %s:%s" % [path, lines.sort.join(",")]
          end
        else
          raise "unsupported style: %p" % [style]
        end
      end
    end

    ##
    # An extra minitest reporter to output how to rerun failures using
    # rake.

    class RakeReporter < SprintReporter
      ##
      # The name of the rake task to rerun. Defaults to nil.

      attr_accessor :name

      def initialize name = nil # :nodoc:
        super()
        self.name    = name
      end

      def print_list # :nodoc:
        results.each do |result|
          puts ["  rake", name, "N=#{result.class_name}##{result.name}"].compact.join(" ")
        end
      end
    end
  end
end
