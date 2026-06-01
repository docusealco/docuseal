module Zeitwerk::Registry
  # Loaders know their own inceptions, but there is a use case in which we need
  # to know if a given cpath is an inception globally. This is what this
  # registry is for.
  class Inceptions # :nodoc:
    #: () -> void
    def initialize
      @inceptions = Zeitwerk::Cref::Map.new #: Zeitwerk::Cref::Map[String]
    end

    #: (Zeitwerk::Cref, String) -> void
    def register(cref, abspath)
      @inceptions[cref] = abspath
    end

    #: (Zeitwerk::Cref) -> String?
    def registered?(cref)
      @inceptions[cref]
    end

    #: (Zeitwerk::Cref) -> void
    def unregister(cref)
      @inceptions.delete(cref)
    end

    #: () -> void
    def clear # for tests
      @inceptions.clear
    end
  end
end
