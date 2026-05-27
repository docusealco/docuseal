require "yaml"
require "json"
require "fileutils"
require "logger"
require "pathname"

module Shakapacker
  class SwcMigrator
    attr_reader :root_path, :logger

    # Babel packages safe to remove when migrating to SWC
    # Note: @babel/core and @babel/eslint-parser are excluded as they may be needed for ESLint
    BABEL_PACKAGES = [
      "@babel/plugin-proposal-class-properties",
      "@babel/plugin-proposal-object-rest-spread",
      "@babel/plugin-syntax-dynamic-import",
      "@babel/plugin-transform-destructuring",
      "@babel/plugin-transform-regenerator",
      "@babel/plugin-transform-runtime",
      "@babel/preset-env",
      "@babel/preset-react",
      "@babel/preset-typescript",
      "@babel/runtime",
      "babel-loader",
      "babel-plugin-macros",
      "babel-plugin-transform-react-remove-prop-types"
    ].freeze

    # Babel packages that may be needed for ESLint - only remove if user explicitly confirms
    ESLINT_BABEL_PACKAGES = [
      "@babel/core",
      "@babel/eslint-parser"
    ].freeze

    SWC_PACKAGES = {
      "@swc/core" => "^1.7.39",
      "swc-loader" => "^0.2.6"
    }.freeze

    ESLINT_CONFIG_FILES = %w[
      .eslintrc
      .eslintrc.js
      .eslintrc.cjs
      .eslintrc.yaml
      .eslintrc.yml
      .eslintrc.json
    ].freeze

    DEFAULT_SWC_CONFIG = <<~JS.freeze
      // config/swc.config.js
      // This file is merged with Shakapacker's default SWC configuration
      // See: https://swc.rs/docs/configuration/compilation

      const { env } = require('shakapacker');

      module.exports = {
        options: {
          jsc: {
            // CRITICAL for Stimulus compatibility: Prevents SWC from mangling class names
            // which breaks Stimulus's class-based controller discovery mechanism
            keepClassNames: true,
            transform: {
              react: {
                runtime: 'automatic',
                refresh: env.isDevelopment && env.runningWebpackDevServer,
              },
            },
          },
        },
      };
    JS

    def initialize(root_path, logger: nil)
      @root_path = Pathname.new(root_path)
      @logger = logger || Logger.new($stdout)
    end

    def migrate_to_swc(run_installer: true)
      logger.info "🔄 Starting migration from Babel to SWC..."

      results = {
        config_updated: update_shakapacker_config,
        packages_installed: install_swc_packages,
        swc_config_created: create_swc_config,
        babel_packages_found: find_babel_packages
      }

      logger.info "🎉 Migration to SWC complete!"
      logger.info "   Note: SWC is approximately 20x faster than Babel for transpilation."
      logger.info "   Please test your application thoroughly after migration."
      logger.info "\n📝 Configuration Info:"
      logger.info "   - config/swc.config.js is merged with Shakapacker's default SWC configuration"
      logger.info "   - You can customize config/swc.config.js to add additional options"
      logger.info "   - Avoid using .swcrc as it overrides Shakapacker defaults completely"

      # Show cleanup recommendations if babel packages found
      if results[:babel_packages_found].any?
        logger.info "\n🧹 Cleanup Recommendations:"
        logger.info "   Found the following Babel packages in your package.json:"
        results[:babel_packages_found].each do |package|
          logger.info "   - #{package}"
        end
        logger.info "\n   To remove them, run:"
        logger.info "   bundle exec rake shakapacker:clean_babel_packages"
      end

      # Suggest running doctor to verify configuration
      logger.info "\n🩺 Run 'bundle exec rake shakapacker:doctor' to verify your configuration"

      # Run package manager install if packages were added
      if run_installer && results[:packages_installed].any?
        run_package_manager_install
      end

      results
    end

    def clean_babel_packages(run_installer: true)
      logger.info "🧹 Removing Babel packages..."

      package_json_path = root_path.join("package.json")
      unless package_json_path.exist?
        logger.error "❌ No package.json found"
        return { removed_packages: [], config_files_deleted: [], preserved_packages: [] }
      end

      # Check if ESLint uses Babel parser
      preserved_for_eslint = []
      if eslint_uses_babel?
        logger.info "\n⚠️  ESLint configuration detected that uses Babel parser"
        logger.info "   Preserving @babel/core and @babel/eslint-parser for ESLint compatibility"
        logger.info "   To switch ESLint parser:"
        logger.info "   1. For TypeScript: use @typescript-eslint/parser"
        logger.info "   2. For JavaScript: use espree (ESLint's default parser)"
        preserved_for_eslint = ESLINT_BABEL_PACKAGES
      end

      removed_packages = remove_babel_from_package_json(package_json_path, preserve: preserved_for_eslint)
      deleted_files = delete_babel_config_files

      if removed_packages.any?
        logger.info "✅ Babel packages removed successfully!"
        run_package_manager_install if run_installer
      else
        logger.info "ℹ️  No Babel packages found to remove"
      end

      { removed_packages: removed_packages, config_files_deleted: deleted_files, preserved_packages: preserved_for_eslint }
    end

    def find_babel_packages
      package_json_path = root_path.join("package.json")
      return [] unless package_json_path.exist?

      begin
        package_json = JSON.parse(File.read(package_json_path))
        dependencies = package_json["dependencies"] || {}
        dev_dependencies = package_json["devDependencies"] || {}
        all_deps = dependencies.merge(dev_dependencies)

        # Find all babel packages (including ESLint-related ones for display)
        all_babel_packages = BABEL_PACKAGES + ESLINT_BABEL_PACKAGES
        found_packages = all_babel_packages.select { |pkg| all_deps.key?(pkg) }
        found_packages
      rescue JSON::ParserError => e
        logger.error "Failed to parse package.json: #{e.message}"
        []
      end
    end

    private

      def eslint_uses_babel?
        # Check for ESLint config files
        # Note: This is a heuristic check that may have false positives (e.g., in comments),
        # but false positives only result in an extra warning, which is safer than silently
        # breaking ESLint configurations.
        ESLINT_CONFIG_FILES.each do |config_file|
          config_path = root_path.join(config_file)
          next unless config_path.exist?

          content = File.read(config_path)
          # Check for Babel parser references
          return true if content.match?(/@babel\/eslint-parser|babel-eslint/)
        end

        # Check package.json for eslintConfig
        package_json_path = root_path.join("package.json")
        if package_json_path.exist?
          begin
            package_json = JSON.parse(File.read(package_json_path))
            if package_json["eslintConfig"]
              # Check parser field explicitly
              parser = package_json["eslintConfig"]["parser"]
              return true if parser && parser.match?(/@babel\/eslint-parser|babel-eslint/)

              # Also check entire config for babel parser references (catches nested configs)
              return true if package_json["eslintConfig"].to_json.match?(/@babel\/eslint-parser|babel-eslint/)
            end

            # Check if Babel ESLint packages are installed
            dependencies = package_json["dependencies"] || {}
            dev_dependencies = package_json["devDependencies"] || {}
            all_deps = dependencies.merge(dev_dependencies)
            return true if all_deps.key?("@babel/eslint-parser") || all_deps.key?("babel-eslint")
          rescue JSON::ParserError => e
            logger.debug "Could not parse package.json for ESLint detection: #{e.message}"
          end
        end

        false
      end

      def update_shakapacker_config
        config_path = root_path.join("config/shakapacker.yml")
        return false unless config_path.exist?

        logger.info "📝 Updating shakapacker.yml..."
        config = begin
          YAML.load_file(config_path, aliases: true)
        rescue ArgumentError
          YAML.load_file(config_path)
        end

        config.each do |env, settings|
          next unless settings.is_a?(Hash)

          if settings["babel"]
            logger.info "  - Removing babel config from #{env} environment"
            settings.delete("babel")
          end

          settings["javascript_transpiler"] = "swc"
          logger.info "  - Set javascript_transpiler to 'swc' for #{env} environment"
        end

        File.write(config_path, config.to_yaml)
        logger.info "✅ shakapacker.yml updated"
        true
      rescue StandardError => e
        logger.error "Failed to update config: #{e.message}"
        false
      end

      def install_swc_packages
        package_json_path = root_path.join("package.json")
        return {} unless package_json_path.exist?

        logger.info "📦 Installing SWC dependencies..."
        package_json = JSON.parse(File.read(package_json_path))

        dependencies = package_json["dependencies"] || {}
        dev_dependencies = package_json["devDependencies"] || {}
        installed = {}

        SWC_PACKAGES.each do |package, version|
          unless dependencies[package] || dev_dependencies[package]
            logger.info "  - Adding #{package}@#{version}"
            dev_dependencies[package] = version
            installed[package] = version
          else
            logger.info "  - #{package} already installed"
          end
        end

        if installed.any?
          package_json["devDependencies"] = dev_dependencies
          File.write(package_json_path, JSON.pretty_generate(package_json) + "\n")
          logger.info "✅ package.json updated with SWC dependencies"
        end

        installed
      rescue StandardError => e
        logger.error "Failed to install packages: #{e.message}"
        {}
      end

      def create_swc_config
        config_dir = root_path.join("config")
        swc_config_path = config_dir.join("swc.config.js")

        if swc_config_path.exist?
          logger.info "ℹ️  config/swc.config.js already exists"
          return false
        end

        FileUtils.mkdir_p(config_dir) unless config_dir.exist?

        logger.info "📄 Creating config/swc.config.js..."
        File.write(swc_config_path, DEFAULT_SWC_CONFIG)
        logger.info "✅ config/swc.config.js created"
        true
      rescue StandardError => e
        logger.error "Failed to create config/swc.config.js: #{e.message}"
        false
      end

      def remove_babel_from_package_json(package_json_path, preserve: [])
        package_json = JSON.parse(File.read(package_json_path))
        dependencies = package_json["dependencies"] || {}
        dev_dependencies = package_json["devDependencies"] || {}
        removed_packages = []

        BABEL_PACKAGES.each do |package|
          next if preserve.include?(package)

          if dependencies.delete(package)
            removed_packages << package
            logger.info "  - Removed #{package} from dependencies"
          end
          if dev_dependencies.delete(package)
            removed_packages << package
            logger.info "  - Removed #{package} from devDependencies"
          end
        end

        # Log preserved packages
        preserve.each do |package|
          if dependencies[package] || dev_dependencies[package]
            logger.info "  - Preserved #{package} (needed for ESLint)"
          end
        end

        if removed_packages.any?
          package_json["dependencies"] = dependencies
          package_json["devDependencies"] = dev_dependencies
          File.write(package_json_path, JSON.pretty_generate(package_json) + "\n")
          logger.info "✅ package.json updated"
        end

        removed_packages.uniq
      rescue StandardError => e
        logger.error "Failed to remove packages: #{e.message}"
        []
      end

      def delete_babel_config_files
        deleted_files = []
        babel_config_files = [".babelrc", "babel.config.js", ".babelrc.js", "babel.config.json"]

        babel_config_files.each do |file|
          file_path = root_path.join(file)
          if file_path.exist?
            logger.info "  - Removing #{file}"
            File.delete(file_path)
            deleted_files << file
          end
        end

        deleted_files
      rescue StandardError => e
        logger.error "Failed to delete config files: #{e.message}"
        []
      end

      def run_package_manager_install
        logger.info "\n🔧 Running npm/yarn install..."

        yarn_lock = root_path.join("yarn.lock")
        pnpm_lock = root_path.join("pnpm-lock.yaml")

        if yarn_lock.exist?
          system("yarn install")
        elsif pnpm_lock.exist?
          system("pnpm install")
        else
          system("npm install")
        end
      end

      def package_manager
        yarn_lock = root_path.join("yarn.lock")
        pnpm_lock = root_path.join("pnpm-lock.yaml")

        if yarn_lock.exist?
          "yarn"
        elsif pnpm_lock.exist?
          "pnpm"
        else
          "npm"
        end
      end
  end
end
