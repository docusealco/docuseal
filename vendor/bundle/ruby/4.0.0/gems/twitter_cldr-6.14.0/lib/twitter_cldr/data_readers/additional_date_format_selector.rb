# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

module TwitterCldr
  module DataReaders
    class AdditionalDateFormatSelector
      attr_reader :pattern_hash

      def initialize(pattern_hash)
        @pattern_hash = pattern_hash
      end

      def find_closest(goal_pattern)
        if !goal_pattern || goal_pattern.strip.empty?
          nil
        else
          cache_key = TwitterCldr::Utils.compute_cache_key(goal_pattern)
          pattern_cache[cache_key] ||= if @pattern_hash.include?(goal_pattern.to_sym)
            goal_pattern.to_sym
          else
            rank(goal_pattern).min do |(p1, score1), (p2, score2)|
              score1 <=> score2
            end.first.to_sym
          end

          @pattern_hash[pattern_cache[cache_key]]
        end
      end

      def patterns
        @pattern_hash.keys.map(&:to_s)
      end

      protected

      def pattern_cache
        @pattern_cache ||= {}
      end

      def separate(pattern_key)
        last_char = ""
        pattern_key.each_char.each_with_index.inject([]) do |ret, (char, index)|
          char == last_char ? ret[-1] += char : ret << char
          last_char = char
          ret
        end
      end

      def all_separated_patterns
        @separated_patterns ||= @pattern_hash.map { |pattern, _| separate(pattern.to_s) }
      end

      def score(entities, goal_entities)
        # weight existence a little more heavily than the others
        score = exist_score(entities, goal_entities) * 2
        score += position_score(entities, goal_entities)
        score + count_score(entities, goal_entities)
      end

      def position_score(entities, goal_entities)
        goal_entities.each_with_index.inject(0) do |sum, (goal_entity, index)|
          if found = entities.index(goal_entity)
            sum + (found - index).abs
          else
            sum
          end
        end
      end

      def exist_score(entities, goal_entities)
        goal_entities.inject(0) do |sum, goal_entity|
          if !entities.any? { |entity| entity[0] == goal_entity[0] }
            sum + 1
          else
            sum
          end
        end
      end

      def count_score(entities, goal_entities)
        goal_entities.inject(0) do |sum, goal_entity|
          if found_entity = entities.select { |entity| entity[0] == goal_entity[0] }.first
            sum + (found_entity.size - goal_entity.size).abs
          else
            sum
          end
        end
      end

      def rank(goal_pattern)
        separated_goal_pattern = separate(goal_pattern)
        all_separated_patterns.inject({}) do |ret, separated_pattern|
          ret[separated_pattern.join] = score(separated_pattern, separated_goal_pattern)
          ret
        end
      end
    end
  end
end