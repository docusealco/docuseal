# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

module TwitterCldr
  module Segmentation
    class RuleSet

      class << self
        def create(locale, boundary_type, options = {})
          new(locale, StateMachine.instance(boundary_type, locale), options)
        end
      end

      attr_reader :locale, :state_machine
      attr_accessor :use_uli_exceptions

      alias_method :use_uli_exceptions?, :use_uli_exceptions

      def initialize(locale, state_machine, options)
        @locale = locale
        @state_machine = state_machine
        @use_uli_exceptions = options.fetch(
          :use_uli_exceptions, false
        )
      end

      def each_boundary(cursor, stop = cursor.length)
        return to_enum(__method__, cursor, stop) unless block_given?

        until cursor.position >= stop || cursor.eos?
          state_machine.handle_next(cursor)
          yield cursor.position if cursor.eos? || suppressions.should_break?(cursor)
        end
      end

      def boundary_type
        state_machine.boundary_type
      end

      private

      def suppressions
        @suppressions ||= if use_uli_exceptions?
          Suppressions.instance(boundary_type, locale)
        else
          NullSuppressions.instance
        end
      end
    end
  end
end
