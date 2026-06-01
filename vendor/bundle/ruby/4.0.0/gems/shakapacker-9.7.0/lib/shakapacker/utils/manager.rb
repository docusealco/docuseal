# frozen_string_literal: true

require "package_json"

module Shakapacker
  module Utils
    class Manager
      class Error < StandardError; end

      MANAGER_LOCKS = {
        "bun" => "bun.lockb",
        "npm" => "package-lock.json",
        "pnpm" => "pnpm-lock.yaml",
        "yarn" => "yarn.lock"
      }

      # Emits a warning if it's not obvious what package manager to use
      def self.error_unless_package_manager_is_obvious!
        return unless PackageJson.read(rails_root).fetch("packageManager", nil).nil?

        guessed_binary = guess_binary

        return if guessed_binary == "npm"

        raise Error, <<~MSG
          You don't have "packageManager" set in your package.json
          meaning that Shakapacker will use npm but you've got a #{MANAGER_LOCKS[guessed_binary]}
          file meaning you probably want to be using #{guessed_binary} instead.

          To make this happen, set "packageManager" in your package.json to #{guessed_binary}@#{guess_version}
        MSG
      end

      # Guesses the binary of the package manager to use based on what lockfiles exist
      #
      # @return [String]
      def self.guess_binary
        MANAGER_LOCKS.find { |_, lock| File.exist?(rails_root.join(lock)) }&.first || "npm"
      end

      # Guesses the version of the package manager to use by calling `<manager> --version`
      #
      # @return [String]
      def self.guess_version
        require "open3"

        command = "#{guess_binary} --version"
        stdout, stderr, status = Open3.capture3(command)

        unless status.success?
          raise Error, "#{command} failed with exit code #{status.exitstatus}: #{stderr}"
        end

        stdout.chomp
      end

      private
        def self.rails_root
          if defined?(APP_ROOT)
            Pathname.new(APP_ROOT)
          elsif ENV["APP_ROOT"]
            Pathname.new(ENV["APP_ROOT"])
          elsif defined?(Rails)
            Rails.root
          else
            raise "can only be called from a rails environment or with APP_ROOT defined"
          end
        end
    end
  end
end
