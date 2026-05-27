# frozen_string_literal: true
require_relative "version"

module Shakapacker
  class VersionChecker
    attr_reader :node_package_version

    MAJOR_MINOR_PATCH_VERSION_REGEX = /(\d+)\.(\d+)\.(\d+)/.freeze

    def self.build
      new(NodePackageVersion.build)
    end

    def initialize(node_package_version)
      @node_package_version = node_package_version
    end

    def raise_if_gem_and_node_package_versions_differ
      # Skip check if package is not in package.json or listed from relative path, git repo or github URL
      # or if consistent version checking is not enabled
      return if node_package_version.skip_processing? || !Shakapacker.config.ensure_consistent_versioning?

      node_major_minor_patch = node_package_version.major_minor_patch
      gem_major_minor_patch = gem_major_minor_patch_version

      raise_differing_versions_warning unless (
        node_major_minor_patch[0] == gem_major_minor_patch[0] &&
        node_major_minor_patch[1] == gem_major_minor_patch[1] &&
        node_major_minor_patch[2] == gem_major_minor_patch[2]
      )

      raise_node_semver_version_warning if node_package_version.semver_wildcard?
    end

    private

      def common_error_msg
        <<-MSG.strip_heredoc
         Detected: #{node_package_version.raw}
              gem: #{gem_version}
         Ensure the installed version of the gem is the same as the version of
         your installed node package.
         Do not use >= or ~> in your Gemfile for shakapacker without a lockfile.
         Do not use ^ or ~ in your package.json for shakapacker without a lockfile.
      MSG
      end

      def raise_differing_versions_warning
        msg = "**ERROR** Shakapacker: Shakapacker gem and node package versions do not match\n#{common_error_msg}"
        raise msg
      end

      def raise_node_semver_version_warning
        msg = "**ERROR** Shakapacker: Your node package version for shakapacker contains a "\
              "^ or ~\n#{common_error_msg}"
        raise msg
      end

      def gem_version
        Shakapacker::VERSION
      end

      def gem_major_minor_patch_version
        match = gem_version.match(MAJOR_MINOR_PATCH_VERSION_REGEX)
        [match[1], match[2], match[3]]
      end

      # TODO: this might as well use package_json
      class NodePackageVersion
        attr_reader :package_json

        def self.build
          new(package_json_path, yarn_lock_path, package_lock_path, pnpm_lock_path)
        end

        def self.package_json_path
          Rails.root.join("package.json")
        end

        def self.yarn_lock_path
          Rails.root.join("yarn.lock")
        end

        def self.package_lock_path
          Rails.root.join("package-lock.json")
        end

        def self.pnpm_lock_path
          Rails.root.join("pnpm-lock.yaml")
        end

        def initialize(package_json, yarn_lock, package_lock, pnpm_lock)
          @package_json = package_json
          @yarn_lock = yarn_lock
          @package_lock = package_lock
          @pnpm_lock = pnpm_lock
        end

        def raw
          @raw ||= find_version
        end

        def semver_wildcard?
          raw.match(/[~^]/).present?
        end

        def skip_processing?
          !package_specified? || relative_path? || git_url? || github_url?
        end

        def major_minor_patch
          return if skip_processing?

          match = raw.match(MAJOR_MINOR_PATCH_VERSION_REGEX)
          unless match
            raise "Cannot parse version number '#{raw}' (wildcard versions are not supported)"
          end

          [match[1], match[2], match[3]]
        end

        private

          def package_specified?
            raw.present?
          end

          def relative_path?
            raw.match(%r{(\.\.|\Afile:)}).present?
          end

          def git_url?
            raw.match(%r{^git}).present?
          end

          def github_url?
            raw.match(%r{^([\w-]+\/[\w-]+)}).present?
          end

          def package_json_contents
            @package_json_contents ||= File.read(package_json)
          end

          def find_version
            if File.exist?(@yarn_lock)
              version = from_yarn_lock

              return version unless version.nil?
            end

            if File.exist?(@package_lock)
              version = from_package_lock

              return version unless version.nil?
            end

            if File.exist?(@pnpm_lock)
              version = from_pnpm_lock

              return version unless version.nil?
            end

            parsed_package_contents = JSON.parse(package_json_contents)
            parsed_package_contents.dig("dependencies", "shakapacker").to_s
          end

          def from_package_lock
            package_lock_contents = File.read(@package_lock)
            parsed_lock_contents = JSON.parse(package_lock_contents)

            pkg = parsed_lock_contents.dig("packages", "node_modules/shakapacker")
            pkg = parsed_lock_contents.dig("dependencies", "shakapacker") if pkg.nil?

            pkg&.fetch("version", nil)
          end

          def from_yarn_lock
            found_pkg = false
            version = nil
            matcher = /\A"?shakapacker@.+:/

            File.foreach(@yarn_lock, chomp: true) do |line|
              next if line.start_with?("#")

              # if we've found the start of the packages details and then come across
              # a line that is not indented we've hit the end of the package details
              break if found_pkg && !line.start_with?("  ")

              if found_pkg
                m = line.match(/\A {2}version:? "?(?<package_version>[\w.-]+)"?\z/)

                next unless m

                version = m[:package_version]
                break
              end

              found_pkg = true if matcher.match(line)
            end

            version
          end

          def from_pnpm_lock
            require "yaml"

            content = YAML.load_file(@pnpm_lock)

            content.fetch("packages", {}).each do |key, value|
              # git-based constraints will include a "version" key with their pseudo semantic version
              return value["version"] if key.start_with?("shakapacker") && value.key?("version")
              return value["version"] if value["name"] == "shakapacker"

              # v9+ uses the same key format just without the leading slash, so we just add one in
              key = "/#{key}" unless key.start_with?("/")

              parts = key.split("/")

              return parts[2] if parts[1] == "shakapacker"
              next unless parts[1].start_with?("shakapacker@")

              _, version = parts[1].split("@")

              return version[0, version.index("(")] if version.include?("(")
              return version
            end

            nil
          end
      end
  end
end
