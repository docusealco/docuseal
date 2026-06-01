class PackageJson
  module Managers
    class PnpmLike < Base
      def initialize(package_json)
        super(package_json, binary_name: "pnpm")
      end

      # Installs the dependencies specified in the `package.json` file
      def install(frozen: false)
        raw("install", with_frozen_flag(frozen))
      end

      # Provides the "native" command for installing dependencies with this package manager for embedding into scripts
      def native_install_command(frozen: false)
        build_full_cmd("install", with_frozen_flag(frozen))
      end

      # Adds the given packages
      def add(packages, type: :production, exact: false)
        flags = [package_type_install_flag(type), exact_flag(exact)].compact
        raw("add", flags + packages)
      end

      # Removes the given packages
      def remove(packages)
        raw("remove", packages)
      end

      # Runs the script assuming it is defined in the `package.json` file
      def run(
        script_name,
        args = [],
        silent: false
      )
        raw("run", build_run_args(script_name, args, silent: silent))
      end

      # Provides the "native" command for running the script with args for embedding into shell scripts
      def native_run_command(
        script_name,
        args = [],
        silent: false
      )
        build_full_cmd("run", build_run_args(script_name, args, silent: silent))
      end

      def native_exec_command(
        script_name,
        args = []
      )
        build_full_cmd("exec", build_run_args(script_name, args, silent: false))
      end

      private

      def build_run_args(script_name, args, silent:)
        args = [script_name, *args]

        args.unshift("--silent") if silent
        args
      end

      def with_frozen_flag(frozen)
        return ["--frozen-lockfile"] if frozen

        # we make frozen lockfile behaviour consistent with the other package managers
        # as pnpm automatically enables frozen lockfile if it detects it's running in CI
        ["--no-frozen-lockfile"]
      end

      def exact_flag(exact)
        return "--save-exact" if exact

        nil
      end

      def package_type_install_flag(type)
        case type
        when :production
          "--save-prod"
        when :dev
          "--save-dev"
        when :optional
          "--save-optional"
        else
          raise Error, "unsupported package install type \"#{type}\""
        end
      end
    end
  end
end
