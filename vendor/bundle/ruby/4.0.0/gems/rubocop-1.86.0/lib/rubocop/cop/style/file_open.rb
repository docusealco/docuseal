# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Checks for `File.open` without a block, which can leak file descriptors.
      #
      # When `File.open` is called without a block, the caller is responsible
      # for closing the file descriptor. If it is not explicitly closed, it
      # will only be closed when the garbage collector runs, which may lead
      # to resource exhaustion. Using the block form ensures the file is
      # automatically closed when the block exits.
      #
      # This cop only registers an offense when the result of `File.open` is
      # assigned to a variable or has a method chained on it, as those are the
      # clearest indicators that the block form should be used instead. When
      # `File.open` is used as a return value or passed as an argument, the
      # caller is likely managing the file descriptor intentionally.
      #
      # @safety
      #   This cop is unsafe because it relies on syntax heuristics and cannot
      #   verify whether the file descriptor is safely managed. For example, it
      #   still flags intentional one-shot reads (`File.open("f").read`) where
      #   the file descriptor is closed by the garbage collector.
      #
      # @example
      #   # bad
      #   f = File.open('file')
      #
      #   # bad
      #   File.open('file').read
      #
      #   # good
      #   File.open('file') do |f|
      #     f.read
      #   end
      #
      #   # good
      #   File.open('file', &:read)
      #
      #   # good - pass an open file object to an API that manages its lifecycle
      #   process(io: File.open('file'))
      #
      #   # good - return an open file object for the caller to manage
      #   def json_key_io
      #     File.open('file')
      #   end
      #
      #   # good - use File.read for one-shot reads
      #   File.read('file')
      #
      class FileOpen < Base
        MSG = '`File.open` without a block may leak a file descriptor; use the block form.'
        RESTRICT_ON_SEND = %i[open].freeze

        # @!method file_open?(node)
        def_node_matcher :file_open?, <<~PATTERN
          (send (const {nil? cbase} :File) :open ...)
        PATTERN

        def on_send(node)
          return unless file_open?(node)
          return if node.block_argument?
          return unless offensive_usage?(node)

          add_offense(node)
        end
        alias on_csend on_send

        private

        def offensive_usage?(node)
          return true unless node.value_used?

          node.parent.lvasgn_type? || receiver_of_chained_call?(node)
        end

        def receiver_of_chained_call?(node)
          node.parent.receiver == node
        end
      end
    end
  end
end
