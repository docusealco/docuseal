# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

require 'set'

module TwitterCldr
  module Shared
    class PostalCodeGenerator

      SAMPLE_MULTIPLIER = 4

      def initialize(regexp_ast)
        @regexp_generator = TwitterCldr::Utils::RegexpSampler.new(regexp_ast)
      end

      def generate
        clean_result(@regexp_generator.generate)
      end

      def sample(sample_size = 1)
        sample_set = Set.new
        counter = 1

        until sample_set.size == sample_size
          sample = generate
          sample_set << sample unless sample.empty?
          counter += 1

          # Stop if the number of attempted generations is
          # n times more than requested. Some territories only
          # have one postal code, so if the user asks for 10
          # they'll get an infinite loop.
          break if counter > sample_size * SAMPLE_MULTIPLIER
        end

        sample_set.to_a
      end

      private

      # remove spaces that trail a dash
      def clean_result(str)
        str.gsub(/- /, '-')
      end

    end
  end
end
