# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

require 'erb'
require 'yaml'

module TwitterCldr
  module Resources

    ReadmeAssertionFailure = Struct.new(:message, :line_number)

    class ReadmeRenderer
      attr_reader :text, :assertion_failures

      def initialize(text)
        @text = text
        @assertion_failures = []
      end

      def render
        ERB.new(text).result(binding)
      end

      def datetime
        @datetime ||= DateTime.new(2014, 2, 14, 12, 20, 5, 0)
      end

      def time
        @time ||= Time.gm(2014, 2, 14, 12, 20, 5, 0)
      end

      private

      def assert(got, expected)
        if got.is_a?(String) && expected.is_a?(String)
          got = got.localize.normalize(using: :NFKC).to_s
          expected = expected.localize.normalize(using: :NFKC).to_s
        end

        unless objs_equal?(got, expected)
          line_num = line_num_from_stack_trace(Kernel.caller)
          assertion_failures << ReadmeAssertionFailure.new(
            "Expected `#{got.inspect}` to be `#{expected.inspect}` in README on line #{line_num}",
            line_num
          )
        end

        got
      end

      def objs_equal?(obj1, obj2)
        case obj1
          when Array
            obj1 - obj2 == []
          else
            obj1 == obj2
        end
      end

      def assert_true(got)
        assert(got, true)
      end

      def assert_false(got)
        assert(got, false)
      end

      def assert_no_error(proc)
        error = nil
        begin
          proc.call
        rescue => e
          line_num = line_num_from_stack_trace(Kernel.caller)
          assertion_failures << ReadmeAssertionFailure.new(
            "Expected README line #{line_num} not to raise an exception, but it did:\n#{e.message}\n#{e.backtrace.join("\n")}",
            line_num
          )
        end
      end

      def line_num_from_stack_trace(trace)
        trace[0].split(":")[1].to_i  # kind of a hack...
      end

      def ellipsize(obj)
        case obj
          when Array
            "[#{obj.map(&:inspect).join(", ")}, ... ]"
          when Hash
            hash_text = obj.map { |key, val| "#{key.inspect} => #{val.inspect}" }.join(", ")
            "{ ... #{hash_text} ... }"
        end
      end

      def slice_hash(hash, keys)
        hash.inject({}) do |ret, (key, val)|
          ret[key] = val if keys.include?(key)
          ret
        end
      end

      def tested_ruby_versions
        workflow = YAML.load_file(File.join(*%w(.github workflows unit_tests.yml)))
        workflow["jobs"]["build"]["strategy"]["matrix"]["ruby-version"].join(", ")
      end
    end

  end
end
