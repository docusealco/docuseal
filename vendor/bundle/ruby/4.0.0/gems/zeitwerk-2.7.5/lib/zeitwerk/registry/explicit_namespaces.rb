# frozen_string_literal: true

module Zeitwerk::Registry
  # A registry for explicit namespaces.
  #
  # When a loader determines that a certain file should define an explicit
  # namespace, it registers it here, associating its cref with itself.
  #
  # If the namespace is autoloaded, our const_added callback retrieves its
  # loader by calling loader_for. That way, the loader is able to scan the
  # subdirectories that conform the namespace and set autoloads for their
  # expected constants just in time.
  #
  # Once autoloaded, the namespace is unregistered.
  #
  # The implementation assumes an explicit namespace is managed by one loader.
  # Loaders that reopen namespaces owned by other projects are responsible for
  # loading their constant before setup. This is documented.
  #
  # **This is a private module.**
  class ExplicitNamespaces # :nodoc: all
    #: () -> void
    def initialize
      # Maps crefs of explicit namespaces with their corresponding loader.
      #
      # Entries are added as the namespaces are found, and removed as they are
      # autoloaded.
      @loaders = Zeitwerk::Cref::Map.new
    end

    # Registers `cref` as being the constant path of an explicit namespace
    # managed by `loader`.
    #
    #: (Zeitwerk::Cref, Zeitwerk::Loader) -> void
    def register(cref, loader)
      @loaders[cref] = loader
    end

    #: (Module, Symbol) -> Zeitwerk::Loader?
    def loader_for(mod, cname)
      @loaders.delete_mod_cname(mod, cname)
    end

    #: (Zeitwerk::Loader) -> void
    def unregister_loader(loader)
      @loaders.delete_by_value(loader)
    end

    # This is an internal method only used by the test suite.
    #
    #: (Zeitwerk::Cref) -> Zeitwerk::Loader?
    def registered?(cref)
      @loaders[cref]
    end

    #: () -> void
    def clear # for tests
      @loaders.clear
    end
  end
end
