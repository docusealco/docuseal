# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

module TwitterCldr
  module Parsers
    class UnicodeRegexParser
      class Component

        protected

        def to_utf8(codepoints)
          Array(codepoints).map { |cp| "\\u{#{cp.to_s(16).rjust(4, "0")}}"}.join
        end

        def range_to_regex(range)
          if range.first.is_a?(Array)
            array_to_regex(range)
          else
            "[#{to_utf8(range.first)}-#{to_utf8(range.last)}]"
          end
        end

        def array_to_regex(arr)
          arr.map { |elem| "(?:#{to_utf8(elem)})" }.join
        end

        def set_to_regex(set)
          strs = set.to_a(true).uniq.map do |obj|
            case obj
              when Range
                range_to_regex(obj)
              when Array
                array_to_regex(obj)
              else
                to_utf8(obj)
            end
          end

          "(?:#{strs.join("|")})"
        end

      end
    end
  end
end
