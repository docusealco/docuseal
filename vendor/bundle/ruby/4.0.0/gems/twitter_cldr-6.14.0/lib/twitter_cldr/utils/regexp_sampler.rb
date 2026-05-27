# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

module TwitterCldr
  module Utils

    # Generates a valid string that would match the given regexp ast.
    class RegexpSampler

      attr_reader :regexp_ast

      DIGITS       = ('0'..'9').to_a
      WORD_LETTERS = ('a'..'z').to_a + ('A'..'Z').to_a + ['_']

      def initialize(regexp_ast)
        @regexp_ast = regexp_ast
      end

      def generate
        walk_children(regexp_ast)
      end

      private

      def walk(node)
        method = :"walk_#{class_name_for(node)}"
        respond_to?(method, true) ? send(method, node) : ""
      end

      def walk_children(node)
        node.expressions.map { |expr| walk(expr) }.join
      end

      def walk_digit(node)
        if node.quantified?
          quantifier_sample(DIGITS, node.quantifier)
        else
          [single_sample(DIGITS)]
        end.join + walk_children(node)
      end

      def walk_word(node)
        if node.quantified?
          quantifier_sample(WORD_LETTERS, node.quantifier)
        else
          [single_sample(WORD_LETTERS)]
        end.join + walk_children(node)
      end

      def walk_literal(node)
        node.text * if node.quantified?
          rand_in_quantifier(node.quantifier)
        else
          1
        end + walk_children(node)
      end

      def walk_character_set(node)
        charset = expand_charset(node.members)

        if node.quantified?
          quantifier_sample(charset, node.quantifier)
        else
          [single_sample(charset)]
        end.join + walk_children(node)
      end

      def walk_capture(node)
        if node.quantified?
          rand_in_quantifier(node.quantifier).times.map do
            walk_children(node)
          end.join
        else
          walk_children(node)
        end
      end

      # "passive" means non-capturing group.
      # Since we don't need to distinguish between
      # captures/non-captures, we can just delegate
      # to the walk_capture method.
      def walk_passive(node)
        walk_capture(node)
      end

      def walk_alternation(node)
        if node.quantified?
          rand_in_quantifier(node.quantifier).times.map do
            walk(single_sample(node.expressions))
          end.join
        else
          walk(single_sample(node.expressions))
        end
      end

      def walk_alternative(node)
        walk_children(node)
      end

      def walk_sequence(node)
        if node.quantified?
          rand_in_quantifier(node.quantifier).times.map do
            node.expressions.map { |expr| walk(expr) }.join
          end.join
        else
          node.expressions.map { |expr| walk(expr) }.join
        end
      end

      def expand_charset(members)
        members.inject([]) do |ret, member|
          ret + expand_charset_member(member)
        end
      end

      def expand_charset_member(member)
        left, right = member.scan(/([^\\])-?/).flatten
        right ? (left..right).to_a : [left]
      end

      def quantifier_sample(arr, quantifier)
        sample_size = if quantifier.min == quantifier.max
          quantifier.min
        else
          rand_in_quantifier(quantifier)
        end

        sample_size.times.map { single_sample(arr) }
      end

      def single_sample(arr)
        arr[rand(arr.size)]
      end

      def rand_in_quantifier(quantifier)
        rand_in_range(quantifier.min, quantifier.max)
      end

      def rand_in_range(min, max)
        min + rand((max - min) + 1)
      end

      def class_name_for(node)
        name = node.class.to_s.split("::").last
        name.gsub(/\A|([A-Z])/) { $1 ? "_#{$1.downcase}" : "" }.downcase
      end

    end
  end
end
