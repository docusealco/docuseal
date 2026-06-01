# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

module TwitterCldr
  module Formatters
    class ListFormatter < Formatter

      attr_accessor :locale

      def initialize(locale = TwitterCldr.locale)
        @locale = TwitterCldr.convert_locale(locale)
      end

      def format(list, type = :default)
        if res = resource_for_type(type)
          if res.include?(:"#{list.size}")
            compose(res[:"#{list.size}"], list)
          else
            compose_list(list, res)
          end
        end
      end

      def types
        resource.keys
      end

      protected

      def compose_list(list, res)
        result = compose(res[:end] || res[:middle] || "", [list[-2], list[-1]])

        # Ruby ranges don't support subtraction for some reason (eg. -3..-5).
        # Instead, we use a positive counter and negate it on array access.
        (3..list.size).each do |i|
          format_sym = i == list.size ? :start : :middle
          format_sym = :middle unless res.include?(format_sym)
          result = compose(res[format_sym] || "", [list[-i], result])
        end

        result
      end

      def compose(format, elements)
        elements.compact!

        if elements.size > 1
          result = format.dup
          result.gsub!(/\{(\d+)\}/) { $1 }  # unfortunately "{" and "}" are weak types - must replace

          if TwitterCldr::Shared::Languages.is_rtl?(@locale)
            result = result.localize.to_reordered_s(direction: :RTL)
          end

          result.gsub!(/(\d)/) { elements[$1.to_i] }
          result
        else
          elements[0] || ""
        end
      end

      def resource_for_type(type)
        loop do
          if resource[type].is_a?(Symbol)
            type = resource[:type].to_s.split('.').last
          else
            break resource[type]
          end
        end
      end

      def resource
        @resource ||= TwitterCldr.get_locale_resource(@locale, :lists)[@locale][:lists]
      end

    end
  end
end
