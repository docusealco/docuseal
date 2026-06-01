# frozen_string_literal: true

module Hashdiff
  # @private
  # Used to compare hashes
  class CompareHashes
    class << self
      def call(obj1, obj2, opts = {})
        return [] if obj1.empty? && obj2.empty?

        obj1_keys = obj1.keys
        obj2_keys = obj2.keys
        obj1_lookup = {}
        obj2_lookup = {}

        if opts[:indifferent]
          obj1_lookup = obj1_keys.each_with_object({}) { |k, h| h[k.to_s] = k }
          obj2_lookup = obj2_keys.each_with_object({}) { |k, h| h[k.to_s] = k }
          obj1_keys = obj1_keys.map { |k| k.is_a?(Symbol) ? k.to_s : k }
          obj2_keys = obj2_keys.map { |k| k.is_a?(Symbol) ? k.to_s : k }
        end

        added_keys = obj2_keys - obj1_keys
        common_keys = obj1_keys & obj2_keys
        deleted_keys = obj1_keys - obj2_keys

        result = []

        opts[:ignore_keys].each do |k|
          added_keys.delete k
          common_keys.delete k
          deleted_keys.delete k
        end

        handle_key = lambda do |k, type|
          case type
          when :deleted
            # add deleted properties
            k = opts[:indifferent] ? obj1_lookup[k] : k
            change_key = Hashdiff.prefix_append_key(opts[:prefix], k, opts)
            custom_result = Hashdiff.custom_compare(opts[:comparison], change_key, obj1[k], nil)

            if custom_result
              result.concat(custom_result)
            else
              result << ['-', change_key, obj1[k]]
            end
          when :common
            # recursive comparison for common keys
            prefix = Hashdiff.prefix_append_key(opts[:prefix], k, opts)

            k1 = opts[:indifferent] ? obj1_lookup[k] : k
            k2 = opts[:indifferent] ? obj2_lookup[k] : k
            result.concat(Hashdiff.diff(obj1[k1], obj2[k2], opts.merge(prefix: prefix)))
          when :added
            # added properties
            change_key = Hashdiff.prefix_append_key(opts[:prefix], k, opts)

            k = opts[:indifferent] ? obj2_lookup[k] : k
            custom_result = Hashdiff.custom_compare(opts[:comparison], change_key, nil, obj2[k])

            if custom_result
              result.concat(custom_result)
            else
              result << ['+', change_key, obj2[k]]
            end
          else
            raise "Invalid type: #{type}"
          end
        end

        if opts[:preserve_key_order]
          # Building lookups to speed up key classification
          added_keys_lookup = added_keys.each_with_object({}) { |k, h| h[k] = true }
          common_keys_lookup = common_keys.each_with_object({}) { |k, h| h[k] = true }
          deleted_keys_lookup = deleted_keys.each_with_object({}) { |k, h| h[k] = true }

          # Iterate through all keys, preserving obj1's key order and appending any new keys from obj2. Shared keys
          # (found in both obj1 and obj2) follow obj1's order since uniq only keeps the first occurrence.
          (obj1_keys + obj2_keys).uniq.each do |k|
            if added_keys_lookup[k]
              handle_key.call(k, :added)
            elsif common_keys_lookup[k]
              handle_key.call(k, :common)
            elsif deleted_keys_lookup[k]
              handle_key.call(k, :deleted)
            end
          end
        else
          # Keys are first grouped by operation type (deletions first, then changes, then additions), and then sorted
          # alphabetically within each group.
          deleted_keys.sort_by(&:to_s).each { |k| handle_key.call(k, :deleted) }
          common_keys.sort_by(&:to_s).each { |k| handle_key.call(k, :common) }
          added_keys.sort_by(&:to_s).each { |k| handle_key.call(k, :added) }
        end

        result
      end
    end
  end
end
