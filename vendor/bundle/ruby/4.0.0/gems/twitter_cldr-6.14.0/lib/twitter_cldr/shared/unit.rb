# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

require 'set'

module TwitterCldr
  module Shared
    class Unit
      class << self
        def create(value, locale = TwitterCldr.locale)
          subtype_for(locale).new(value, locale)
        end

        private

        def reader_for(locale)
          readers[locale] ||= TwitterCldr::DataReaders::NumberDataReader.new(locale)
        end

        def resource_for(locale)
          TwitterCldr.get_locale_resource(locale, :units)[locale][:units]
        end

        def subtype_for(locale)
          subtypes[locale] ||= begin
            klass = Class.new(Unit)

            all_unit_types_for(locale).each do |unit_type|
              method_name = unit_type_to_method_name(unit_type)
              klass.send(:define_method, method_name) do |*args|
                format(unit_type, *args)
              end
            end

            klass
          end
        end

        def all_unit_types_for(locale)
          unit_types[locale] ||= begin
            resource = resource_for(locale)
            lengths = resource[:unitLength].keys

            lengths.each_with_object(Set.new) do |length, ret|
              ret.merge(resource[:unitLength][length].keys)
            end
          end
        end

        def all_unit_methods_for(locale)
          unit_methods[locale] ||= all_unit_types_for(locale).map do |unit_type|
            unit_type_to_method_name(unit_type).to_sym
          end
        end

        def unit_type_to_method_name(unit_type)
          unit_type.to_s.gsub('-', '_')
        end

        def subtypes
          @subtypes ||= {}
        end

        def unit_types
          @unit_types ||= {}
        end

        def unit_methods
          @unit_methods ||= {}
        end

        def readers
          @readers ||= {}
        end
      end

      DEFAULT_FORM = :long

      attr_reader :value, :locale

      def initialize(value, locale = TwitterCldr.locale)
        @value = value
        @locale = locale
      end

      def unit_types
        self.class.send(:all_unit_methods_for, locale)
      end

      private

      def format(unit_type, options = {})
        form = options.fetch(:form, DEFAULT_FORM)
        variant = variant_for(form, unit_type) || variant_for(DEFAULT_FORM, unit_type)
        variant.sub('{0}', formatted_value) if variant
      end

      def formatted_value
        if value.is_a?(Numeric)
          self.class.send(:reader_for, locale).format_number(value)
        else
          value
        end
      end

      def variant_for(form, unit_type)
        variant = resource[:unitLength]
          .fetch(form, {})
          .fetch(unit_type, {})
          .fetch(plural_rule.to_sym, nil)
      end

      def plural_rule
        TwitterCldr::Formatters::Plurals::Rules.rule_for(value, locale)
      end

      def resource
        @resource ||= self.class.send(:resource_for, locale)
      end
    end
  end
end
