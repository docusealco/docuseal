# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

module TwitterCldr
  module Localized
    class LocalizedNumber < LocalizedObject

      attr_reader :type, :format

      def initialize(obj, locale, options = {})
        @type = options[:type]
        @format = options[:format]
        super
      end

      class << self
        def types
          TwitterCldr::DataReaders::NumberDataReader.types
        end
      end

      types.each do |type|
        define_method "to_#{type}" do
          to_type(type)
        end
      end

      def to_s(options = {})
        opts = { type: @type, format: @format }.merge(options)

        TwitterCldr::DataReaders::NumberDataReader
          .new(locale, opts)
          .format_number(base_obj, opts)
      end

      def plural_rule
        TwitterCldr::Formatters::Plurals::Rules.rule_for(base_obj, locale)
      end

      def spellout
        rbnf.format(
          base_obj, TwitterCldr::Formatters::Rbnf::RbnfFormatter::DEFAULT_SPELLOUT_OPTIONS
        )
      end

      def to_rbnf_s(group_name, rule_set_name)
        rbnf.format(base_obj, {
          rule_group: group_name,
          rule_set: rule_set_name
        })
      end

      def rbnf
        @rbnf ||= TwitterCldr::Formatters::Rbnf::RbnfFormatter.new(locale)
      end

      def to_unit
        TwitterCldr::Shared::Unit.create(base_obj, locale)
      end

      private

      def to_type(target_type)
        self.class.new(base_obj, locale, {
          type: target_type,
          format: @format
        })
      end

    end
  end
end
