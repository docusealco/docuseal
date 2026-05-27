# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

module TwitterCldr
  module Utils

    autoload :CodePoints,            'twitter_cldr/utils/code_points'
    autoload :FileSystemTrie,        'twitter_cldr/utils/file_system_trie'
    autoload :RangeSet,              'twitter_cldr/utils/range_set'
    autoload :RegexpAst,             'twitter_cldr/utils/regexp_ast'
    autoload :RegexpSampler,         'twitter_cldr/utils/regexp_sampler'
    autoload :ScriptDetector,        'twitter_cldr/utils/script_detector'
    autoload :ScriptDetectionResult, 'twitter_cldr/utils/script_detector'
    autoload :Trie,                  'twitter_cldr/utils/trie'
    autoload :YAML,                  'twitter_cldr/utils/yaml'

    class << self

      # adapted from: http://snippets.dzone.com/posts/show/11121 (first comment)
      def deep_symbolize_keys(arg)
        case arg
          when Array
            arg.map { |elem| deep_symbolize_keys(elem) }
          when Hash
            Hash[arg.map { |k, v| [k.is_a?(String) ? k.to_sym : k, deep_symbolize_keys(v)] }]
          else
            arg
        end
      end

      def deep_merge!(first, second)
        if first.is_a?(Hash) && second.is_a?(Hash)
          second.each { |key, val| first[key] = deep_merge!(first[key], val) }
        elsif first.is_a?(Array) && second.is_a?(Array)
          second.each_with_index { |elem, index| first[index] = deep_merge!(first[index], elem) }
        else
          return second
        end
        first
      end

      def deep_merge_hash(first, second, &block)
        target = first.dup

        second.keys.each do |key|
          if second[key].is_a?(Hash) && first[key].is_a?(Hash)
            target[key] = deep_merge_hash(target[key], second[key], &block)
            next
          end

          target[key] = block_given? ? yield(first[key], second[key]) : second[key]
        end

        target
      end

      def compute_cache_key(*pieces)
        if pieces && pieces.size > 0
          pieces.join("|").hash
        else
          0
        end
      end

      def traverse_hash(hash, path, &block)
        return if path.empty?

        path.inject(hash) do |current, key|
          return unless current.is_a?(Hash)

          if block
            yield key, current[key]
          else
            current[key]
          end
        end
      end

    end

  end
end
