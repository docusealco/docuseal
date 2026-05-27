module MultiXML
  # Mixin providing configurable parse options
  #
  # Supports static hashes or dynamic callables (procs/lambdas). Extended
  # into MultiXML so callers configure process-wide defaults via
  # {MultiXML.parse_options=}.
  #
  # @api private
  module Options
    # Frozen empty hash used as the zero-default for parse options.
    EMPTY_OPTIONS = {}.freeze

    # Set options for parse operations
    #
    # @api public
    # @param options [Hash, Proc] options hash or callable
    # @return [Hash, Proc] the options
    # @example
    #   MultiXML.parse_options = {symbolize_names: true}
    def parse_options=(options)
      @parse_options = options
    end

    # Get options for parse operations
    #
    # When ``@parse_options`` is a callable (proc/lambda), it's invoked
    # with ``args`` as positional arguments — typically the call-site
    # options hash. When it's a plain hash, ``args`` is ignored.
    #
    # @api public
    # @param args [Array<Object>] forwarded to the callable, ignored otherwise
    # @return [Hash] resolved options hash
    # @example
    #   MultiXML.parse_options  #=> {}
    def parse_options(*)
      resolve_options(@parse_options, *) || EMPTY_OPTIONS
    end

    private

    # Resolves options from a hash or callable
    #
    # @api private
    # @param options [Hash, Proc, nil] options configuration
    # @param args [Array<Object>] arguments forwarded to a callable provider
    # @return [Hash, nil] resolved options hash
    def resolve_options(options, *)
      return invoke_callable(options, *) if options.respond_to?(:call)

      options.to_hash if options.respond_to?(:to_hash)
    end

    # Invokes a callable options provider
    #
    # @api private
    # @param callable [Proc] options provider
    # @param args [Array<Object>] arguments forwarded when the callable is non-arity-zero
    # @return [Hash] options returned by the callable
    def invoke_callable(callable, *)
      callable.arity.zero? ? callable.call : callable.call(*)
    end
  end
end
