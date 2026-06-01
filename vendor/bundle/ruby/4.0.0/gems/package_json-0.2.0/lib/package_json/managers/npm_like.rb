class PackageJson
  module Managers
    class NpmLike < Base
      def initialize(package_json)
        super(package_json, binary_name: "npm")
      end

      # Installs the dependencies specified in the `package.json` file
      def install(frozen: false)
        cmd = "install"
        cmd = "ci" if frozen

        raw(cmd, [])
      end

      # Provides the "native" command for installing dependencies with this package manager for embedding into scripts
      def native_install_command(frozen: false)
        cmd = "install"
        cmd = "ci" if frozen

        build_full_cmd(cmd, [])
      end

      # Adds the given packages
      def add(packages, type: :production, exact: false)
        flags = [package_type_install_flag(type), exact_flag(exact)].compact
        raw("install", flags + packages)
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
        build_full_cmd("exec", ["--no", "--offline"] + build_run_args(script_name, args, silent: false))
      end

      private

      def build_run_args(script_name, args, silent:)
        # npm assumes flags prefixed with - are for it, unless they come after a "--"
        args = [script_name, "--", *args]

        args.unshift("--silent") if silent
        args
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
