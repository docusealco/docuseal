module Zeitwerk::Registry
  class Loaders # :nodoc:
    #: () -> void
    def initialize
      @loaders = [] #: Array[Zeitwerk::Loader]
    end

    #: ({ (Zeitwerk::Loader) -> void }) -> void
    def each(&)
      @loaders.each(&)
    end

    #: (Zeitwerk::Loader) -> void
    def register(loader)
      @loaders << loader
    end

    #: (Zeitwerk::Loader) -> Zeitwerk::Loader?
    def unregister(loader)
      @loaders.delete(loader)
    end

    #: (Zeitwerk::Loader) -> bool
    def registered?(loader) # for tests
      @loaders.include?(loader)
    end

    #: () -> void
    def clear # for tests
      @loaders.clear
    end
  end
end
