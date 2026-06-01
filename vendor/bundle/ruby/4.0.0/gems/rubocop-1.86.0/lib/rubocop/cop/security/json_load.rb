# frozen_string_literal: true

module RuboCop
  module Cop
    module Security
      # Checks for the use of JSON class methods which have potential
      # security issues.
      #
      # `JSON.load` and similar methods allow deserialization of arbitrary ruby objects:
      #
      # [source,ruby]
      # ----
      # require 'json/add/string'
      # result = JSON.load('{ "json_class": "String", "raw": [72, 101, 108, 108, 111] }')
      # pp result # => "Hello"
      # ----
      #
      # Never use `JSON.load` for untrusted user input. Prefer `JSON.parse` unless you have
      # a concrete use-case for `JSON.load`.
      #
      # NOTE: Starting with `json` gem version 2.8.0, triggering this behavior without explicitly
      # passing the `create_additions` keyword argument emits a deprecation warning, with the
      # goal of being secure by default in the next major version 3.0.0.
      #
      # @safety
      #   This cop's autocorrection is unsafe because it's potentially dangerous.
      #   If using a stream, like `JSON.load(open('file'))`, you will need to call
      #   `#read` manually, like `JSON.parse(open('file').read)`.
      #   Other similar issues may apply.
      #
      # @example
      #   # bad
      #   JSON.load('{}')
      #   JSON.restore('{}')
      #
      #   # good
      #   JSON.parse('{}')
      #   JSON.unsafe_load('{}')
      #
      #   # good - explicit use of `create_additions` option
      #   JSON.load('{}', create_additions: true)
      #   JSON.load('{}', create_additions: false)
      #
      class JSONLoad < Base
        extend AutoCorrector

        MSG = 'Prefer `JSON.parse` over `JSON.%<method>s`.'
        RESTRICT_ON_SEND = %i[load restore].freeze

        # @!method insecure_json_load(node)
        def_node_matcher :insecure_json_load, <<~PATTERN
          (
            send (const {nil? cbase} :JSON) ${:load :restore}
            ...
            !`(pair (sym :create_additions) _)
          )
        PATTERN

        def on_send(node)
          insecure_json_load(node) do |method|
            add_offense(node.loc.selector, message: format(MSG, method: method)) do |corrector|
              corrector.replace(node.loc.selector, 'parse')
            end
          end
        end
      end
    end
  end
end
