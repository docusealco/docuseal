module FactoryBot
  module Syntax
    ## This module is a container for all strategy methods provided by
    ## FactoryBot. This includes all the default strategies provided ({Methods#build},
    ## {Methods#create}, {Methods#build_stubbed}, and {Methods#attributes_for}), as
    ## well as the complementary *_list and *_pair methods.
    ## @example singular factory execution
    ##   # basic use case
    ##   build(:completed_order)
    ##
    ##   # factory yielding its result to a block
    ##   create(:post) do |post|
    ##     create(:comment, post: post)
    ##   end
    ##
    ##   # factory with attribute override
    ##   attributes_for(:post, title: "I love Ruby!")
    ##
    ##   # factory with traits and attribute override
    ##   build_stubbed(:user, :admin, :male, name: "John Doe")
    ##
    ## @example multiple factory execution
    ##   # basic use case
    ##   build_list(:completed_order, 2)
    ##   create_list(:completed_order, 2)
    ##
    ##   # factory with attribute override
    ##   attributes_for_list(:post, 4, title: "I love Ruby!")
    ##
    ##   # factory with traits and attribute override
    ##   build_stubbed_list(:user, 15, :admin, :male, name: "John Doe")
    module Methods
      # @!parse FactoryBot::Internal.register_default_strategies
      # @!method build(name, *traits_and_overrides, &block)
      # (see #strategy_method)
      # Builds a registered factory by name.
      # @return [Object] instantiated object defined by the factory

      # @!method create(name, *traits_and_overrides, &block)
      # (see #strategy_method)
      # Creates a registered factory by name.
      # @return [Object] instantiated object defined by the factory

      # @!method build_stubbed(name, *traits_and_overrides, &block)
      # (see #strategy_method)
      # Builds a stubbed registered factory by name.
      # @return [Object] instantiated object defined by the factory

      # @!method attributes_for(name, *traits_and_overrides, &block)
      # (see #strategy_method)
      # Generates a hash of attributes for a registered factory by name.
      # @return [Hash] hash of attributes for the factory

      # @!method build_list(name, amount, *traits_and_overrides, &block)
      # (see #strategy_method_list)
      # @return [Array] array of built objects defined by the factory

      # @!method create_list(name, amount, *traits_and_overrides, &block)
      # (see #strategy_method_list)
      # @return [Array] array of created objects defined by the factory

      # @!method build_stubbed_list(name, amount, *traits_and_overrides, &block)
      # (see #strategy_method_list)
      # @return [Array] array of stubbed objects defined by the factory

      # @!method attributes_for_list(name, amount, *traits_and_overrides, &block)
      # (see #strategy_method_list)
      # @return [Array<Hash>] array of attribute hashes for the factory

      # @!method build_pair(name, *traits_and_overrides, &block)
      # (see #strategy_method_pair)
      # @return [Array] pair of built objects defined by the factory

      # @!method create_pair(name, *traits_and_overrides, &block)
      # (see #strategy_method_pair)
      # @return [Array] pair of created objects defined by the factory

      # @!method build_stubbed_pair(name, *traits_and_overrides, &block)
      # (see #strategy_method_pair)
      # @return [Array] pair of stubbed objects defined by the factory

      # @!method attributes_for_pair(name, *traits_and_overrides, &block)
      # (see #strategy_method_pair)
      # @return [Array<Hash>] pair of attribute hashes for the factory

      # @!method strategy_method(name, traits_and_overrides, &block)
      # @!visibility private
      # @param [Symbol] name the name of the factory to build
      # @param [Array<Symbol, Symbol, Hash>] traits_and_overrides splat args traits and a hash of overrides
      # @param [Proc] block block to be executed

      # @!method strategy_method_list(name, amount, traits_and_overrides, &block)
      # @!visibility private
      # @param [Symbol] name the name of the factory to execute
      # @param [Integer] amount the number of instances to execute
      # @param [Array<Symbol, Symbol, Hash>] traits_and_overrides splat args traits and a hash of overrides
      # @param [Proc] block block to be executed

      # @!method strategy_method_pair(name, traits_and_overrides, &block)
      # @!visibility private
      # @param [Symbol] name the name of the factory to execute
      # @param [Array<Symbol, Symbol, Hash>] traits_and_overrides splat args traits and a hash of overrides
      # @param [Proc] block block to be executed

      # Generates and returns the next value in a global or factory sequence.
      #
      # Arguments:
      #   context: (Array of Symbols)
      #     The definition context of the sequence, with the sequence name
      #     as the final entry
      #   scope: (object)(optional)
      #     The object the sequence should be evaluated within
      #
      # Returns:
      #   The next value in the sequence. (Object)
      #
      # Example:
      #   generate(:my_factory, :my_trair, :my_sequence)
      #
      def generate(*uri_parts, scope: nil)
        uri = FactoryBot::UriManager.build_uri(uri_parts)
        sequence = Sequence.find_by_uri(uri) ||
          raise(KeyError,
            "Sequence not registered: #{FactoryBot::UriManager.build_uri(uri_parts)}")

        increment_sequence(sequence, scope: scope)
      end

      # Generates and returns the list of values in a global or factory sequence.
      #
      # Arguments:
      #   uri_parts: (Array of Symbols)
      #     The definition context of the sequence, with the sequence name
      #     as the final entry
      #   scope: (object)(optional)
      #     The object the sequence should be evaluated within
      #
      # Returns:
      #   The next value in the sequence. (Object)
      #
      # Example:
      #   generate_list(:my_factory, :my_trair, :my_sequence, 5)
      #
      def generate_list(*uri_parts, count, scope: nil)
        uri = FactoryBot::UriManager.build_uri(uri_parts)
        sequence = Sequence.find_by_uri(uri) ||
          raise(KeyError, "Sequence not registered: '#{uri}'")

        (1..count).map do
          increment_sequence(sequence, scope: scope)
        end
      end

      # ======================================================================
      # = PRIVATE
      # ======================================================================
      #
      private

      ##
      # Increments the given sequence and returns the value.
      #
      # Arguments:
      #   sequence:
      #     The sequence instance
      #   scope: (object)(optional)
      #     The object the sequence should be evaluated within
      #
      def increment_sequence(sequence, scope: nil)
        value = sequence.next(scope)

        raise if value.respond_to?(:start_with?) && value.start_with?("#<FactoryBot::Declaration")

        value
      rescue
        raise ArgumentError, "Sequence '#{sequence.uri_manager.first}' failed to " \
                            "return a value. Perhaps it needs a scope to operate? (scope: <object>)"
      end
    end
  end
end
