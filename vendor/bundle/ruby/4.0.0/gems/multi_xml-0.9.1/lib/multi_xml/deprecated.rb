# Deprecated public API kept around for one major release
#
# Each method here emits a one-time deprecation warning on first call and
# delegates to its current-API counterpart. The whole file is loaded by
# {MultiXML} so the deprecation surface stays out of the main module
# definition.
#
# @api private
module MultiXML
  class << self
    private

    # Define a deprecated alias that delegates to a new method name
    #
    # The generated singleton method emits a one-time deprecation
    # warning naming the replacement, then forwards all positional and
    # keyword arguments plus any block to replacement.
    #
    # @api private
    # @param name [Symbol] deprecated method name
    # @param replacement [Symbol] current-API method to delegate to
    # @return [Symbol] the defined method name
    # @example
    #   deprecate_alias :load, :parse
    def deprecate_alias(name, replacement)
      message = "MultiXML.#{name} is deprecated and will be removed in v1.0. Use MultiXML.#{replacement} instead."
      define_singleton_method(name) do |*args, **kwargs, &block|
        warn_deprecation_once(name, message)
        public_send(replacement, *args, **kwargs, &block)
      end
    end
  end

  deprecate_alias :load, :parse
end
