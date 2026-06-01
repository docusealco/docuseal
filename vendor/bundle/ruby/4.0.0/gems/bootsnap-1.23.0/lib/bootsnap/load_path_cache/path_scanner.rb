# frozen_string_literal: true

require_relative "../explicit_require"

module Bootsnap
  module LoadPathCache
    module PathScanner
      REQUIRABLE_EXTENSIONS = [DOT_RB] + DL_EXTENSIONS

      BUNDLE_PATH = if Bootsnap.bundler?
        (Bundler.bundle_path.cleanpath.to_s << LoadPathCache::SLASH).freeze
      else
        ""
      end

      @ignored_directories = %w(node_modules)

      class << self
        attr_accessor :ignored_directories

        def ruby_call(root_path)
          root_path, contains_bundle_path, ignored_abs_paths, ignored_dir_names = prepare_scan(root_path)
          return [] unless File.directory?(root_path)

          requirables = []
          walk(root_path, nil, ignored_abs_paths, ignored_dir_names) do |relative_path, absolute_path, is_directory|
            if is_directory
              !contains_bundle_path || !absolute_path.start_with?(BUNDLE_PATH)
            elsif relative_path.end_with?(*REQUIRABLE_EXTENSIONS)
              requirables << relative_path.freeze
            end
          end
          requirables
        end

        if RUBY_ENGINE == "ruby" && RUBY_PLATFORM.match?(/darwin|linux|bsd|mswin|mingw|cygwin/)
          require "bootsnap/bootsnap"
        end

        if defined?(Native.scan_dir)
          def native_call(root_path)
            # NOTE: if https://bugs.ruby-lang.org/issues/21800 is accepted we should be able
            # to have similar performance with pure Ruby
            root_path, contains_bundle_path, ignored_abs_paths, ignored_dir_names = prepare_scan(root_path)

            all_requirables, queue = Native.scan_dir(root_path)
            all_requirables.each(&:freeze)

            queue.reject! do |dir|
              if ignored_dir_names&.include?(dir)
                true
              elsif ignored_abs_paths || contains_bundle_path
                absolute_dir = File.join(root_path, dir)
                ignored_abs_paths&.include?(absolute_dir) ||
                  (contains_bundle_path && absolute_dir.start_with?(BUNDLE_PATH))
              end
            end

            while (relative_path = queue.pop)
              absolute_base = File.join(root_path, relative_path)
              requirables, dirs = Native.scan_dir(absolute_base)
              dirs.reject! do |dir|
                if ignored_dir_names&.include?(dir)
                  true
                elsif ignored_abs_paths || contains_bundle_path
                  absolute_dir = File.join(absolute_base, dir)
                  ignored_abs_paths&.include?(absolute_dir) ||
                    (contains_bundle_path && absolute_dir.start_with?(BUNDLE_PATH))
                end
              end
              dirs.map! { |f| File.join(relative_path, f).freeze }
              requirables.map! { |f| File.join(relative_path, f).freeze }

              all_requirables.concat(requirables)
              queue.concat(dirs)
            end

            all_requirables
          end
          alias_method :call, :native_call
        else
          alias_method :call, :ruby_call
        end

        private

        def prepare_scan(root_path)
          root_path = File.expand_path(root_path.to_s).freeze

          # If the bundle path is a descendent of this path, we do additional
          # checks to prevent recursing into the bundle path as we recurse
          # through this path. We don't want to scan the bundle path because
          # anything useful in it will be present on other load path items.
          #
          # This can happen if, for example, the user adds '.' to the load path,
          # and the bundle path is '.bundle'.
          contains_bundle_path = BUNDLE_PATH.start_with?(root_path)

          ignored_abs_paths, ignored_dir_names = ignored_directories.partition { |p| File.absolute_path?(p) }
          ignored_abs_paths = nil if ignored_abs_paths.empty?
          ignored_dir_names = nil if ignored_dir_names.empty?

          [root_path, contains_bundle_path, ignored_abs_paths, ignored_dir_names]
        end

        def walk(absolute_dir_path, relative_dir_path, ignored_abs_paths, ignored_dir_names, &block)
          Dir.foreach(absolute_dir_path) do |name|
            next if name.start_with?(".")

            relative_path = relative_dir_path ? File.join(relative_dir_path, name) : name

            absolute_path = File.join(absolute_dir_path, name)
            if File.directory?(absolute_path)
              next if ignored_dir_names&.include?(name) || ignored_abs_paths&.include?(absolute_path)

              if yield relative_path, absolute_path, true
                walk(absolute_path, relative_path, ignored_abs_paths, ignored_dir_names, &block)
              end
            else
              yield relative_path, absolute_path, false
            end
          end
        end
      end
    end
  end
end
