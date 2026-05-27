# frozen_string_literal: true

module Zeitwerk
  module Registry # :nodoc: all
    require_relative "registry/autoloads"
    require_relative "registry/explicit_namespaces"
    require_relative "registry/inceptions"
    require_relative "registry/loaders"

    class << self
      # Keeps track of all loaders. Useful to broadcast messages and to prevent
      # them from being garbage collected.
      #
      # @private
      #: Zeitwerk::Registry::Loaders
      attr_reader :loaders

      # Registers gem loaders to let `for_gem` be idempotent in case of reload.
      #
      # @private
      #: Hash[String, Zeitwerk::Loader]
      attr_reader :gem_loaders_by_root_file

      # Maps absolute paths to the loaders responsible for them.
      #
      # This information is used by our decorated `Kernel#require` to be able to
      # invoke callbacks and autovivify modules.
      #
      # @private
      #: Zeitwerk::Registry::Autoloads
      attr_reader :autoloads

      # @private
      #: Zeitwerk::Registry::ExplicitNamespaces
      attr_reader :explicit_namespaces

      # @private
      #: Zeitwerk::Registry::Inceptions
      attr_reader :inceptions

      # @private
      #: (Zeitwerk::Loader) -> void
      def unregister_loader(loader)
        gem_loaders_by_root_file.delete_if { |_, l| l == loader }
      end

      #: (Zeitwerk::Loader, String) -> Zeitwerk::Loader?
      def conflicting_root_dir?(loader, new_root_dir)
        @mutex.synchronize do
          loaders.each do |existing_loader|
            next if existing_loader == loader

            existing_loader.__roots.each_key do |existing_root_dir|
              # Conflicting directories are rare, optimize for the common case.
              next if !new_root_dir.start_with?(existing_root_dir) && !existing_root_dir.start_with?(new_root_dir)

              new_root_dir_slash = new_root_dir + "/"
              existing_root_dir_slash = existing_root_dir + "/"
              next if !new_root_dir_slash.start_with?(existing_root_dir_slash) && !existing_root_dir_slash.start_with?(new_root_dir_slash)

              next if loader.__ignores?(existing_root_dir)
              break if existing_loader.__ignores?(new_root_dir)

              return existing_loader
            end
          end

          nil
        end
      end

      # This method returns always a loader, the same instance for the same root
      # file. That is how Zeitwerk::Loader.for_gem is idempotent.
      #
      # @private
      #: (String, namespace: Module, warn_on_extra_files: boolish) -> Zeitwerk::Loader
      def loader_for_gem(root_file, namespace:, warn_on_extra_files:)
        gem_loaders_by_root_file[root_file] ||= GemLoader.__new(root_file, namespace: namespace, warn_on_extra_files: warn_on_extra_files)
      end
    end

    @loaders                  = Loaders.new
    @gem_loaders_by_root_file = {}
    @autoloads                = Autoloads.new
    @explicit_namespaces      = ExplicitNamespaces.new
    @inceptions               = Inceptions.new
    @mutex                    = Mutex.new
  end
end
