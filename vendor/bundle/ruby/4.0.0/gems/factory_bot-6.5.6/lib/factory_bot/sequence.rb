require "timeout"

module FactoryBot
  # Sequences are defined using sequence within a FactoryBot.define block.
  # Sequence values are generated using next.
  # @api private
  class Sequence
    attr_reader :name, :uri_manager, :aliases

    def self.find(*uri_parts)
      if uri_parts.empty?
        fail ArgumentError, "wrong number of arguments, expected 1+)"
      else
        find_by_uri FactoryBot::UriManager.build_uri(*uri_parts)
      end
    end

    def self.find_by_uri(uri)
      uri = uri.to_sym
      FactoryBot::Internal.sequences.to_a.find { |seq| seq.has_uri?(uri) } ||
        FactoryBot::Internal.inline_sequences.find { |seq| seq.has_uri?(uri) }
    end

    def initialize(name, *args, &proc)
      options = args.extract_options!
      @name = name
      @proc = proc
      @aliases = options.fetch(:aliases, []).map(&:to_sym)
      @uri_manager = FactoryBot::UriManager.new(names, paths: options[:uri_paths])
      @value = args.first || 1

      unless @value.respond_to?(:peek)
        @value = EnumeratorAdapter.new(@value)
      end
    end

    def next(scope = nil)
      if @proc && scope
        scope.instance_exec(value, &@proc)
      elsif @proc
        @proc.call(value)
      else
        value
      end
    ensure
      increment_value
    end

    def names
      [@name] + @aliases
    end

    def has_name?(test_name)
      names.include?(test_name.to_sym)
    end

    def has_uri?(uri)
      uri_manager.include?(uri)
    end

    def for_factory?(test_factory_name)
      FactoryBot::Internal.factory_by_name(factory_name).names.include?(test_factory_name.to_sym)
    end

    def rewind
      @value.rewind
    end

    ##
    # If it's an Integer based sequence, set the new value directly,
    # else rewind and seek from the beginning until a match is found.
    #
    def set_value(new_value)
      if can_set_value_directly?(new_value)
        @value.set_value(new_value)
      elsif can_set_value_by_index?
        set_value_by_index(new_value)
      else
        seek_value(new_value)
      end
    end

    protected

    attr_reader :proc

    private

    def value
      @value.peek
    end

    def increment_value
      @value.next
    end

    def can_set_value_by_index?
      @value.respond_to?(:find_index)
    end

    ##
    # Set to the given value, or fail if not found
    #
    def set_value_by_index(value)
      index = @value.find_index(value) || fail_value_not_found(value)
      @value.rewind
      index.times { @value.next }
    end

    ##
    # Rewind index and seek until the value is found or the max attempts
    # have been tried. If not found, the sequence is rewound to its original value
    #
    def seek_value(value)
      original_value = @value.peek

      # rewind and search for the new value
      @value.rewind
      Timeout.timeout(FactoryBot.sequence_setting_timeout) do
        loop do
          return if @value.peek == value
          increment_value
        end

        # loop auto-recues a StopIteration error, so if we
        # reached this point, re-raise it now
        fail StopIteration
      end
    rescue Timeout::Error, StopIteration
      reset_original_value(original_value)
      fail_value_not_found(value)
    end

    def reset_original_value(original_value)
      @value.rewind

      until @value.peek == original_value
        increment_value
      end
    end

    def can_set_value_directly?(value)
      return false unless value.is_a?(Integer)
      return false unless @value.is_a?(EnumeratorAdapter)
      @value.integer_value?
    end

    def fail_value_not_found(value)
      fail ArgumentError, "Unable to find '#{value}' in the sequence."
    end

    class EnumeratorAdapter
      def initialize(initial_value)
        @initial_value = initial_value
      end

      def peek
        value
      end

      def next
        @value = value.next
      end

      def rewind
        @value = first_value
      end

      def set_value(new_value)
        if new_value >= first_value
          @value = new_value
        else
          fail ArgumentError, "Value cannot be less than: #{@first_value}"
        end
      end

      def integer_value?
        first_value.is_a?(Integer)
      end

      private

      def first_value
        @first_value ||= initial_value
      end

      def value
        @value ||= initial_value
      end

      def initial_value
        @value = @initial_value.respond_to?(:call) ? @initial_value.call : @initial_value
        @first_value = @value
      end
    end
  end
end
