# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

module TwitterCldr
  module Shared

    class UnsupportedNumberingSystemError < StandardError; end

    class NumberingSystem

      class << self
        def for_name(name)
          name_cache[name] ||= begin
            if system = resource[name.to_sym]
              if system[:type] != "numeric"
                raise UnsupportedNumberingSystemError.new("#{system[:type]} numbering systems not supported.")
              else
                new(system[:name], system[:digits])
              end
            end
          end
        end

        def for_locale(locale, format = :decimal)
          locale_cache[locale] ||= begin
            num_resource = TwitterCldr.get_locale_resource(locale, :numbers)

            system_name = TwitterCldr::Utils.traverse_hash(
              num_resource[locale], [:numbers, :formats, format, :number_system]
            )

            system_name ||= TwitterCldr::Utils.traverse_hash(
              num_resource[locale], [:numbers, :default_number_systems, :default]
            )

            for_name(system_name) if system_name
          end
        end

        private

        def locale_cache
          @locale_cache ||= {}
        end

        def name_cache
          @name_cache ||= {}
        end

        def resource
          @resource ||= TwitterCldr.get_resource(:shared, :numbering_systems)[:numbering_systems]
        end
      end

      attr_reader :name, :digits

      def initialize(name, digits)
        @name = name
        @digits = split_digits(digits)
      end

      def transliterate(number)
        number.to_s.gsub(/\d/) do |digit|
          digits[digit.to_i]
        end
      end

      private

      def split_digits(str)
        str.unpack("U*").map { |digit| [digit].pack("U*") }
      end

    end
  end
end
