# frozen_string_literal: true

require_relative "error"
require_relative "api"

module VersionGem
  # Support for Epoch Semantic Versioning
  # See: https://antfu.me/posts/epoch-semver
  module Epoch
    EPOCH_SIZE = 1_000

    class << self
      def extended(base)
        raise Error, "VERSION must be defined before 'extend #{name}'" unless defined?(base::VERSION)

        base.extend(Api)
        base.extend(OverloadApiForEpoch)
      end
    end

    # Tweak the basic API so it will support Epoch Semantic Versioning
    module OverloadApiForEpoch
      # *** OVERLOAD METHODS FROM API ***
      #
      # The epoch version
      #
      # @return [Integer]
      def epoch
        @epoch ||= _major / EPOCH_SIZE
      end

      # The major version
      #
      # @return [Integer]
      def major
        @major ||= _major % EPOCH_SIZE
      end

      # The version number as a hash
      #
      # @return [Hash]
      def to_h
        @to_h ||= {
          epoch: epoch,
          major: major,
          minor: minor,
          patch: patch,
          pre: pre,
        }
      end

      # NOTE: This is not the same as _to_a, which returns an array of strings
      #
      # The version number as an array of cast values
      # where epoch and major are derived from a single string:
      #   EPOCH * 1000 + MAJOR
      #
      # @return [Array<[Integer, String, NilClass]>]
      def to_a
        @to_a ||= [epoch, major, minor, patch, pre]
      end

      private

      def _major
        @_major ||= _to_a[0].to_i
      end
    end
  end
end
