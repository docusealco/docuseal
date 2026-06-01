# frozen_string_literal: true

module RuboCop
  module Cop
    module Rails
      # Checks for uses of `redirect_back(fallback_location: ...)` and
      # suggests using `redirect_back_or_to(...)` instead.
      #
      # `redirect_back(fallback_location: ...)` was soft deprecated in Rails 7.0 and
      # `redirect_back_or_to` was introduced as a replacement.
      #
      # @example
      #   # bad
      #   redirect_back(fallback_location: root_path)
      #
      #   # good
      #   redirect_back_or_to(root_path)
      #
      #   # bad
      #   redirect_back(fallback_location: root_path, allow_other_host: false)
      #
      #   # good
      #   redirect_back_or_to(root_path, allow_other_host: false)
      #
      class RedirectBackOrTo < Base
        extend AutoCorrector
        extend TargetRailsVersion

        minimum_target_rails_version 7.0

        MSG = 'Use `redirect_back_or_to` instead of `redirect_back` with `:fallback_location` keyword argument.'
        RESTRICT_ON_SEND = %i[redirect_back].freeze

        def_node_matcher :redirect_back_with_fallback_location, <<~PATTERN
          (send nil? :redirect_back
            (hash <$(pair (sym :fallback_location) $_) $...>)
          )
        PATTERN

        def on_send(node)
          redirect_back_with_fallback_location(node) do |fallback_pair, fallback_value, options|
            add_offense(node.loc.selector) do |corrector|
              correct_redirect_back(corrector, node, fallback_pair, fallback_value, options)
            end
          end
        end

        private

        # rubocop:disable Metrics/AbcSize
        def correct_redirect_back(corrector, node, fallback_pair, fallback_value, options)
          corrector.replace(node.loc.selector, 'redirect_back_or_to')

          hash_arg = node.first_argument

          if hash_arg.pairs.one?
            arguments = [fallback_value.source] + options.map(&:source)
            corrector.replace(hash_arg, arguments.join(', '))
          else
            remove_fallback_location_pair(corrector, hash_arg, fallback_pair)
            first_pair = hash_arg.pairs.find { |pair| pair != fallback_pair }
            corrector.insert_before(first_pair, "#{fallback_value.source}, ")
          end

          wrap_with_parentheses(node, corrector) unless node.parenthesized?
        end
        # rubocop:enable Metrics/AbcSize

        def remove_fallback_location_pair(corrector, hash_node, fallback_pair)
          pairs = hash_node.pairs
          index = pairs.index(fallback_pair)

          if pairs.one?
            corrector.remove(fallback_pair)
          elsif index.zero?
            remove_first_pair(corrector, fallback_pair, pairs[1])
          else
            remove_non_first_pair(corrector, fallback_pair, pairs[index - 1])
          end
        end

        def wrap_with_parentheses(node, corrector)
          corrector.replace(node.loc.selector.end.join(node.first_argument.source_range.begin), '(')
          corrector.insert_after(node, ')')
        end

        def remove_first_pair(corrector, fallback_pair, next_pair)
          range = fallback_pair.source_range.join(next_pair.source_range.begin)
          corrector.remove(range)
        end

        def remove_non_first_pair(corrector, fallback_pair, prev_pair)
          range = prev_pair.source_range.end.join(fallback_pair.source_range.end)
          corrector.remove(range)
        end
      end
    end
  end
end
