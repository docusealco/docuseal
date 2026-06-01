# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

require 'forwardable'

module TwitterCldr
  module Shared
    # @note Properties are mostly accessed through the {TwitterCldr::Shared::CodePoint} class. {TwitterCldr::Shared::PropertySet} is used internally.
    class PropertySet
      include TwitterCldr::Shared::Properties
      extend SingleForwardable

      attr_reader :properties_hash

      def_delegators :properties_hash, :empty?, :include?, :size

      def initialize(properties_hash)
        @properties_hash = properties_hash
      end

      # @example
      #   properties = TwitterCldr::Shared::CodePoint.get(12367).properties
      #   properties.age # => #<Set: {"1.1"}>
      def age
        properties_hash.fetch('Age', ['Unassigned'])
      end

      # @example
      #   # ZERO WIDTH JOINER
      #   properties = TwitterCldr::Shared::CodePoint.get(0x200D).properties
      #   properties.joining_type # => #<Set: {"Join_Causing"}>
      #   # SPACE
      #   properties = TwitterCldr::Shared::CodePoint.get(32).properties
      #   properties.joining_type # => ["Non_Joining", "Non_Joining"]
      def joining_type
        properties_hash['Joining_Type'] ||= if general_category.empty?
          [ArabicShaping.joining_type_for_general_category('xx')]
        else
          general_category.map do |gc|
            ArabicShaping.joining_type_for_general_category(gc)
          end
        end
      end

      def bidi_paired_bracket_type
        properties_hash['Bidi_Paired_Bracket_Type'] ||= [
          BidiBrackets.bracket_types['N']
        ]
      end

      # @example
      #   properties = TwitterCldr::Shared::CodePoint.get(0x200D).properties
      #   properties.block # => #<Set: {"General Punctuation"}>
      def block
        properties_hash['Block'] ||= ['No_Block']
      end

      def east_asian_width
        properties_hash['East_Asian_Width'] ||= ['N']
      end

      def grapheme_cluster_break
        properties_hash['Grapheme_Cluster_Break'] ||= ['Other']
      end

      def hangul_syllable_type
        properties_hash['Hangul_Syllable_Type'] ||= ['Not_Applicable']
      end

      def indic_positional_category
        properties_hash['Indic_Positional_Category'] ||= ['NA']
      end

      def indic_syllabic_category
        properties_hash['Indic_Syllabic_Category'] ||= ['Other']
      end

      def jamo_short_name
        properties_hash['Jamo_Short_Name'] ||= ['<none>']
      end

      def line_break
        properties_hash['Line_Break'] ||= ['XX']
      end

      def general_category
        properties_hash.fetch('General_Category', [])
      end

      def script_extensions
        properties_hash['Script_Extensions'] ||= ['<script>']
      end

      def script
        properties_hash['Script'] ||= ['Unknown']
      end

      def sentence_break
        properties_hash['Sentence_Break'] ||= ['Other']
      end

      def word_break
        properties_hash['Word_Break'] ||= ['Other']
      end

      module AdditionalPropertyMethods
        CodePoint.properties.property_names.each do |property_name|
          method_name = property_name.downcase

          unless PropertySet.method_defined?(method_name)
            define_method(method_name) do
              if properties_hash.include?(property_name)
                properties_hash[property_name] || true
              else
                false
              end
            end
          end
        end
      end

      include AdditionalPropertyMethods
    end
  end
end
