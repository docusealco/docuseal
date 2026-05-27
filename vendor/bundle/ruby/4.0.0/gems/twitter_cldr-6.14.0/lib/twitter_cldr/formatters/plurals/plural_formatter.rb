# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

require 'json'

module TwitterCldr
  module Formatters
    class PluralFormatter

      PLURALIZATION_REGEXP = Regexp.union(
        /%\{(\w+?):(\w+?)\}/,   # regular pluralization pattern
        /%<(\{.*?\})>/          # inline pluralization pattern
      )

      class << self
        def for_locale(locale)
          formatter_cache[locale] ||= PluralFormatter.new(locale)
        end

        protected

        def formatter_cache
          @formatter_cache ||= {}
        end
      end

      attr_reader :locale

      def initialize(locale = TwitterCldr.locale)
        @locale = TwitterCldr.convert_locale(locale)
      end

      # Replaces every pluralization token in the +string+ with a phrase formed using a number and a pluralization
      # pattern from the +replacements+ hash.
      #
      # Two types of formatting are supported for pluralization.
      #
      # * Regular pluralization:
      #
      #   Format of a pluralization group is '%{number:objects}'. When pluralization group like that is encountered in
      #   the +string+, +replacements+ hash is expected to contain a number and pluralization patterns at keys +:number+
      #   and +:objects+ respectively (note, keys of the +replacements+ hash should be symbols).
      #
      #   Pluralization patterns are specified as a hash containing a pattern for every plural category of the language.
      #   Keys of this hash should be symbols. If necessary, pluralization pattern can contain placeholder for the number.
      #   Syntax for the placeholder is similar to the hash-based string interpolation: '%{number}.
      #
      # * Inline pluralization:
      #
      #   Pluralization group if formatted as '%<{ "number": { "one": "one horse" } }>'. Content inside '%<...>' is
      #   expected to be a valid string representation of a JSON object with a single key-value pair (JSON property),
      #   where key matches key in the +replacements+ hash (e.g., in this example +replacements+ hash can be something
      #   like { :number => 3 }), and value is a hash (JSON object) of pluralization rules to be used with this number.
      #   No space is allowed inside opening '%<{' and closing '}>' sequences. As pluralization group is parsed as JSON
      #   all keys and string values inside it should be enclosed in double quotes.
      #
      # Examples:
      #
      #   f.format('%{count:horses}', :count => 1, :horses => { :one => 'one horse', :other => '%{count} horses' })
      #   # => "one horse"
      #
      #   f.format('%{count:horses}', :count => 2, :horses => { :one => 'one horse', :other => '%{count} horses' })
      #   # => "2 horses"
      #
      #   f.format('%<{ "count": {"one": "one horse", "other": "%{count} horses"} }>', :count => 2)
      #   # => "2 horses"
      #
      # Multiple pluralization groups can be present in the same string.
      #
      # Examples:
      #
      #   f.format(
      #       '%{ponies_count:ponies} and %{unicorns_count:unicorns}',
      #       :ponies_count   => 2, :ponies   => { :one => 'one pony',    :other => '%{ponies_count} ponies' },
      #       :unicorns_count => 1, :unicorns => { :one => 'one unicorn', :other => '%{unicorns_count} unicorns' }
      #   )
      #   # => "2 ponies and one unicorn"
      #
      # The same applies to inline pluralization.
      #
      # Mixed styles of pluralization (both regular and inline) can be used in the same string, but it's better to avoid
      # that as it might bring more confusion than real benefit.
      #
      # If a number or required pluralization pattern is missing in the +replacements+ hash, corresponding
      # pluralization token is ignored.
      #
      # Examples:
      #
      #   f.format('%{count:horses}', :horses => { :one => 'one horse', :other => '%{count} horses' })
      #   # => "%{count:horses}"
      #
      #   f.format('%<{"count": {"one": "one horse", "other": "%{count} horses"}}>', {})
      #   # => '%<{"count": {"one": "one horse", "other": "%{count} horses"}}>'
      #
      #   f.format('%{count:horses}', :count => 10, :horses => { :one => 'one horse' })
      #   # => "%{count:horses}"
      #
      #   f.format('%<{"count": {"one": "one horse"}}>', :count => 2)
      #   # => '%<{"count": {"one": "one horse"}}>'
      #
      #   f.format('%{count:horses}', {})
      #   # => "%{count:horses}"
      #
      def format(string, replacements)
        string.gsub(PLURALIZATION_REGEXP) do |match|
          number_placeholder, patterns = if $3
            parse_inline_pluralization($3)
          else
            [$1, replacements[$2.to_sym]]
          end

          number  = replacements[number_placeholder.to_sym]
          pattern = pluralization_pattern(patterns, number)

          pattern && interpolate_pattern(pattern, number_placeholder, number) || match
        end
      end

      private

      def parse_inline_pluralization(captured_group)
        pluralization_hash = JSON.parse(captured_group)

        if pluralization_hash.is_a?(Hash) && pluralization_hash.size == 1
          pluralization_hash.first
        else
          raise ArgumentError.new('expected a Hash with a single key')
        end
      end

      def pluralization_rule(number)
        TwitterCldr::Formatters::Plurals::Rules.rule_for(number, locale)
      end

      def pluralization_pattern(patterns, number)
        return unless number && patterns

        if patterns.is_a?(Hash)
          TwitterCldr::Utils.deep_symbolize_keys(patterns)[pluralization_rule(number)]
        else
          raise ArgumentError.new('expected patterns to be a Hash')
        end
      end

      def interpolate_pattern(pattern, placeholder, number)
        pattern.gsub("%{#{placeholder}}", number.to_s)
      end

    end
  end
end