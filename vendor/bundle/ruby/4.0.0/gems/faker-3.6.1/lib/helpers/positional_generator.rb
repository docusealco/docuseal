# frozen_string_literal: true

##
# A high level way to generate a list of generated values that fit a specific
# format, such as an ID, postal code, or phone number.
#
# It provides generators for random digits and letters, hardcoded literal
# strings, computed values based on previously-generated values, union (one-of)
# selectors, and grouped generators.
#
# The generation allows for dependencies on previously generated values -- most
# useful for computations -- and this object knows how to build that dependency
# graph.
#
# See {PositionalGenerator::Builder} for more.
class PositionalGenerator
  ##
  # @param as_type [Symbol] +:string+ to generate a String
  # @param block [Method] a function that interacts with the {Builder}
  def initialize(as_type, &block)
    @block = block
    @generator_builder = Builder.new(as_type)
  end

  ##
  # @return [String] if +as_type+ is +:string+
  def generate
    @block.call(@generator_builder)
    @generator_builder.build
  end

  Component = Struct.new(:position, :name, :deps, :generator)

  class Builder
    attr_reader :as_type

    def initialize(as_type)
      @components = []
      @as_type = as_type
    end

    ##
    # Generate a value in the range of 0..9.
    #
    # @param name [Symbol] the name for this node in the group
    # @param length [Integer] how many digits to generate
    # @param ranges [Array<Range, Array, Set>] an array of limitations on the
    #   generation. Elements can be a Range to select from within that range,
    #   or an Array or Set to select an element from within the list.
    # @return [void]
    #
    # @example a digit
    #   int
    #
    # @example five digits named :a
    #   int(name: :a, length: 5)
    #
    # @example digits of any length between 4 to 10
    #   int(ranges: [1_000 .. 9_999_999_999)
    def int(name: nil, length: 1, ranges: nil)
      @components << Component.new(@components.count, name, [], Int.new(length, ranges))
    end

    ##
    # Generate a value in the range of 'a'..'Z'.
    #
    # @param name [Symbol] the name for this node in the group
    # @param length [Integer, Range] how many letters to generate
    # @param ranges [Array<Range, Array, Set>] an array of limitations on the
    #   generation. Elements can be a Range to select from within that range,
    #   or an Array or Set to select an element from within the list.
    # @return [void]
    #
    # @example Generate a letter
    #   letter
    #
    # @example Generate five uppercase letters named :b
    #   letter(name: :b, length: 5, ranges: ['A'..'Z'])
    #
    # @example Generate three-letter strings from within specific values
    #   letter(ranges: ['700'..'799', '7A0'..'7F9'])
    def letter(name: nil, length: 1, ranges: ['a'..'z', 'A'..'Z'])
      @components << Component.new(@components.count, name, [], Letter.new(length, ranges))
    end

    ##
    # Generate a literal String
    #
    # @param value [String]
    # @param name [Symbol] the name for this node in the group
    # @return [void]
    # @example
    #   lit("-")
    def lit(value, name: nil)
      @components << Component.new(@components.count, name, [], Literal.new(value))
    end

    ##
    # Fill the position with an arbitrary value.
    #
    # @param name [Symbol] the name for this node in the group
    # @param deps [Array<Symbol>] the name of other fields that this one depends on
    # @param block [Method] the block that yields the arbitrary value. Its
    #   arguments are the deps.
    # @return [void]
    #
    # @example Today's date
    #   computed do
    #     Date.today
    #   end
    #
    # @example A check digit
    #   int(name: :a, length: 5)
    #   computed(deps: [:a]) do |a|
    #     a.to_s.bytes.sum % 10
    #   end
    def computed(name: nil, deps: [], &block)
      @components << Component.new(@components.count, name, deps, Computed.new(block))
    end

    ##
    # Fill the position with one of the results from the given generators.
    #
    # @param name [Symbol] the name for this node in the group
    # @param block [Method] subgenerator block
    # @return [void]
    #
    # @example Either five digits, or two letters
    #   oneof do |or_else|
    #     or_else.int(length: 5)
    #     or_else.letter(length: 2)
    #   end
    #
    # @example Either one letter; or a slash, five digits, then a slash.
    #   oneof do |or_else|
    #     or_else.letter
    #     or_else.group do |g_|
    #       g_.lit("/")
    #       g_.digit(length: 5)
    #       g_.lit("/")
    #     end
    #   end
    def oneof(name: nil, &block)
      @components << Component.new(@components.count, name, [], Oneof.new(self, block))
    end

    ##
    # A group of generators. Useful for {#oneof}.
    #
    # @param name [Symbol] the name for this node in the group
    # @param block [Method] a subgenerator block
    # @return [void]
    def group(name: nil, &block)
      @components << Component.new(@components.count, name, [], Group.new(@as_type, block))
    end

    ##
    # Generate the value.
    #
    # @return [String] if +as_type+ is +:string+
    def build
      graph = build_graph
      stack = build_stack(graph)
      values = generate_values(stack)
      convert(values)
    end

    private

    ##
    # Turn the components into a graph following dependencies.
    #
    # @return [Array<(Integer, Integer)>]
    #
    # Components can have dependencies. Here's one where a computation (b)
    # depends on a value generated after it (c):
    #
    #     @components = [
    #       Int.new(0, :a, 1, nil),
    #       Computed.new(1, :b, [:c]) { |c| c + 1 },
    #       Int.new(2, :c, 1, nil),
    #     ]
    #
    # We can think of a graph like so:
    #
    #      (a)  (c)
    #       |    |
    #       |   (b)
    #       \   /
    #        end
    #
    # Or in Mermaid:
    #
    # ```mermaid
    # stateDiagram-v2
    #     a --> [*]
    #     c --> b
    #     b --> [*]
    # ```
    #
    # This method builds that graph, using their positional locations as the
    # ID. The end state is represented as +nil+. So continuing the example
    # above, it will give this output:
    #
    #     [
    #       [0, nil],
    #       [2, 1],
    #       [1, nil],
    #     ]
    #
    # Later we can look up the appropriate component by indexing into the
    # +@components+ array.
    def build_graph
      graph = []

      # rubocop:disable Style/CombinableLoops
      @components.each do |component|
        component.deps.each do |dep|
          dep_component = @components.detect { |c| c.name == dep }
          raise if dep_component.nil?

          graph.push([dep_component.position, component.position])
        end
      end

      @components.each do |component|
        graph.push([component.position, nil]) if graph.none? { |(from, _to)| from == component.position }
      end
      # rubocop:enable Style/CombinableLoops

      graph
    end

    ##
    # Produce a stack of components to evaluate in sequence.
    #
    # @param graph [Array<(Integer, Integer)>]
    # @return [Array<Array<Int>>]
    #
    # Now that we have a graph, we know enough to determine how to traverse the
    # generators such that all dependencies are met.
    #
    # The initial stack is an array of all the free traversals to the goal
    # (where the +to+ is +nil+).
    #
    # Loop over the top of the stack:
    # - The next array is all the nodes that lead into the nodes atop the
    #    stack.
    # - If the next array has values, push that onto the top of the stack.
    # - If the next array is empty, we are done.
    #
    # For example, given the graph:
    #
    #     [
    #       [0, nil],
    #       [2, 1],
    #       [1, nil],
    #     ]
    #
    # The initial stack is:
    #
    #     [
    #       [0, 1]
    #     ]
    #
    # We loop over the top of the stack, +[0, 1]+, and find all the nodes of
    # the graph that lead there. Nothing leads to +0+, and +2+ leads to +1+.
    #
    # Therefore, push +[2]+ to the top of the stack.
    #
    # Repeat for +[2]+. Nothing leads to +2+, so our new goal is +[]+. This is
    # empty, so don't push it onto the stack. We are done.
    #
    # The final stack is:
    #
    #     [
    #       [0, 1],
    #       [2]
    #     ]
    def build_stack(graph)
      require 'set'

      terminals = graph.filter_map { |(from, to)| to.nil? && from }
      stack = [terminals]
      seen = Set.new(terminals)
      deps = []

      loop do
        stack[-1].each do |e|
          deps = graph.select { |(from, to)| to == e && !seen.include?(from) }.map do |from, _to|
            seen << from
            from
          end
          stack << deps if deps.any?
        end

        break if deps.empty?
      end

      stack
    end

    ##
    # Turn a stack into a list of generated values.
    #
    # @param stack [Array<Array<Int>>]
    # @return [Array<Object>] values sorted by desired order
    #
    # We start with a stack of components we need evaluated. We have been
    # tracking these components by position, so first we need to look up the
    # component in our list.
    #
    # From there we can get a list of all the dependencies for the component.
    # These have already been evaluated, since +stack+ is sorted, so we fetch
    # them.
    #
    # Since the stack was sorted by computation order, we must re-sort them
    # into positional order at the end.
    def generate_values(stack)
      result = []

      while (top = stack.pop)
        top.each do |component_id|
          component = @components[component_id]
          raise if component.nil?

          values = result.filter_map do |(_id, name, value)|
            value if component.deps.include?(name)
          end

          result << [component.position, component.name, component.generator.generate(values)]
        end
      end

      result.sort_by do |component_position, _, _|
        component_position
      end
    end

    ##
    # @param values [Array<Object>]
    # @return [String] if +@as_type+ is +:string+
    # @raise [ArgumentError] if +@as_type+ is unsupported
    def convert(values)
      case @as_type
      when :string
        values.inject('') do |acc, (_, _, v)|
          "#{acc}#{v}"
        end
      else
        raise ArgumentError, "unknown return type: #{@as_type}"
      end
    end

    class Group
      def initialize(as_type, block)
        @as_type = as_type
        @block = block
      end

      def generate(_)
        builder = Builder.new(@as_type)
        @block.call(builder)
        builder.build
      end
    end

    class Oneof
      def initialize(builder, block)
        @block = block
        @builder = builder
      end

      def generate(...)
        subgens = OneofSelector.new(@builder)
        @block.call(subgens)
        subgens.sample
        subgens.generate(...)
      end

      class OneofSelector
        def initialize(builder)
          @subgens = []
          @builder = Builder.new(builder.as_type)
        end

        def method_missing(meth, *args, **kwargs, &block)
          @subgens << [meth, args, kwargs, block]
        end

        def respond_to_missing?(method_name, include_private = false)
          @builder.respond_to?(method_name, include_private)
        end

        def sample
          (meth, args, kwargs, block) = Faker::Base.sample(@subgens)
          @builder.send(meth, *args, **kwargs, &block)
        end

        def generate(...)
          @builder.build
        end
      end
    end

    class Int
      def initialize(length, ranges)
        # Internally we store only an Enumerable of Range values. So if we are
        # not given any Ranges but are given a length, we need to convert the
        # length to a Range.
        #
        # If the length is `5`, that means we should compute the Range `10000..99999`.
        # We can compute the lower end with a simple exponent: 10^4 = 10000.
        # The upper end is one less than an exponent: 10^5 - 1 = 99999.
        if ranges.nil?
          lower = 10**(length - 1)
          upper = (10**length) - 1
          ranges = [lower..upper]
        end

        @ranges = ranges
      end

      def generate(_)
        Faker::Base.rand(@ranges.sample(random: Faker::Config.random))
      end
    end

    class Letter
      def initialize(length, ranges)
        @length = length
        @ranges = ranges
      end

      def generate(_)
        @length.times.inject('') do |acc, _index|
          generated_character = char
          "#{acc}#{generated_character}"
        end
      end

      private

      def char
        if @ranges
          case s = @ranges.sample(random: Faker::Config.random)
          when Range
            s.to_a.sample(random: Faker::Config.random)
          when Array, Set
            s.sample(random: Faker::Config.random)
          else
            raise ArgumentError, "unsupported range type: #{s.inspect}"
          end
        else
          Faker::Base.sample(Faker::Base::Letters)
        end
      end
    end

    class Literal
      def initialize(value)
        @value = value
      end

      def generate(_)
        @value
      end
    end

    class Computed
      def initialize(block)
        @block = block
      end

      def generate(args)
        @block.call(*args)
      end
    end
  end
end
