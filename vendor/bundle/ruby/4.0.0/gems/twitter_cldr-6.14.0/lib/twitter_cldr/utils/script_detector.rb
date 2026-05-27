# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

module TwitterCldr
  module Utils
    class ScriptDetectionResult

      attr_reader :scores

      def initialize(scores)
        @scores = scores
      end

      def best_guess
        max_score = scores.max_by { |(_, score)| score }
        max_score.first if max_score
      end

      def score_for(script_name)
        scores[script_name]
      end

      def scripts
        scores.keys
      end

    end

    class ScriptDetector

      PROPERTY_NAME = 'Script'

      class << self

        def detect_scripts(text)
          length = text.length.to_f

          ScriptDetectionResult.new(
            scores_for(text).each_with_object({}) do |(script_name, count), ret|
              ret[script_name] = count / length
            end
          )
        end

        private

        def scores_for(text)
          Hash.new(0).tap do |result|
            text.chars.each do |char|
              script = scripts_hash[char]
              result[script] += 1 if script
            end
          end
        end

        def scripts_hash
          @scripts_hash ||= scripts.each_with_object({}) do |script_name, ret|
            code_points = properties.code_points_for_property(PROPERTY_NAME, script_name)
            code_points.each do |code_point|
              ret[[code_point].pack("U*")] = script_name
            end
          end
        end

        def scripts
          @scripts ||= properties.property_values_for(PROPERTY_NAME)
        end

        def properties
          TwitterCldr::Shared::CodePoint.properties
        end

      end

    end
  end
end
