module MultiXML
  # Catalog of process-wide mutexes used to serialize MultiXML's mutable
  # state. Each mutex protects a distinct piece of state. Callers go
  # through {.synchronize} rather than touching the mutex constants
  # directly so the constants themselves can stay {.private_constant}
  # and the surface of the module is documented in one place.
  #
  # @api private
  module Concurrency
    # Catalog of mutexes keyed by symbolic name. Each entry maps the
    # public name passed to {.synchronize} to the underlying mutex
    # instance.
    MUTEXES = {
      # Guards the DEPRECATION_WARNINGS_SHOWN set in MultiXML so the
      # check-then-add pair in warn_deprecation_once doesn't race.
      deprecation_warnings: Mutex.new
    }.freeze
    private_constant :MUTEXES

    # Run a block while holding the named mutex
    #
    # @api private
    # @param name [Symbol] mutex identifier
    # @yield block to execute while holding the mutex
    # @return [Object] the block's return value
    # @raise [KeyError] when name does not match a known mutex
    def self.synchronize(name, &)
      MUTEXES.fetch(name).synchronize(&)
    end
  end
end
