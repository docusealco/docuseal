require "shakapacker/utils/misc"
require "shakapacker/utils/manager"
require "shakapacker/utils/version_syntax_converter"
require "shakapacker/install/env"
require "package_json"
require "yaml"
require "json"

# Install Shakapacker

@conflict_option = Shakapacker::Install::Env.conflict_option

# Initialize variables for use throughout the template
# Using instance variable to avoid method definition issues in Rails templates
@package_json ||= PackageJson.new
install_dir = File.expand_path(File.dirname(__FILE__))

# Installation strategy:
# - USE_BABEL_PACKAGES installs both babel AND swc for compatibility
# - Otherwise install only the specified transpiler
if Shakapacker::Install::Env.truthy_env?("USE_BABEL_PACKAGES")
  @transpiler_to_install = "babel"
  @install_swc_compat_packages = true
  say "📦 Installing Babel packages (USE_BABEL_PACKAGES is set)", :yellow
  say "✨ Also installing SWC packages for default config compatibility", :green
elsif ENV["JAVASCRIPT_TRANSPILER"]
  @transpiler_to_install = ENV["JAVASCRIPT_TRANSPILER"]
  @install_swc_compat_packages = false
  say "📦 Installing #{@transpiler_to_install} packages", :blue
else
  # Default to swc (matches the default in shakapacker.yml)
  @transpiler_to_install = "swc"
  @install_swc_compat_packages = false
  say "✨ Installing SWC packages (20x faster than Babel)", :green
end

# Copy config file
shakapacker_config_preexisting = Rails.root.join("config/shakapacker.yml").exist?
copy_file "#{install_dir}/config/shakapacker.yml", "config/shakapacker.yml", @conflict_option

# Update config to match the selected transpiler
# Skip modification only when SKIP mode preserved a pre-existing user file
if Shakapacker::Install::Env.update_transpiler_config?(
  transpiler_to_install: @transpiler_to_install,
  conflict_option: @conflict_option,
  config_preexisting: shakapacker_config_preexisting
)
  gsub_file "config/shakapacker.yml", 'javascript_transpiler: "swc"', "javascript_transpiler: \"#{@transpiler_to_install}\""
  say "   📝 Updated config/shakapacker.yml to use #{@transpiler_to_install} transpiler", :green
end

# Detect TypeScript usage
# Auto-detect from tsconfig.json or explicit via SHAKAPACKER_USE_TYPESCRIPT env var
@use_typescript = File.exist?(Rails.root.join("tsconfig.json")) ||
  Shakapacker::Install::Env.truthy_env?("SHAKAPACKER_USE_TYPESCRIPT")
assets_bundler = ENV["SHAKAPACKER_ASSETS_BUNDLER"] || "webpack"
config_extension = @use_typescript ? "ts" : "js"

say "Copying #{assets_bundler} core config (#{config_extension.upcase})"
config_file = "#{assets_bundler}.config.#{config_extension}"
source_config = "#{install_dir}/config/#{assets_bundler}/#{config_file}"
dest_config = "config/#{assets_bundler}/#{config_file}"

empty_directory "config/#{assets_bundler}"
copy_file source_config, dest_config, @conflict_option

if @use_typescript
  say "   ✨ Using TypeScript config for enhanced type safety", :green
end

if Dir.exist?(Shakapacker.config.source_path)
  say "The packs app source directory already exists"
else
  say "Creating packs app source directory"
  empty_directory "app/javascript/packs"
  copy_file "#{install_dir}/application.js", "app/javascript/packs/application.js"
end

apply "#{install_dir}/binstubs.rb"

git_ignore_path = Rails.root.join(".gitignore")
if File.exist?(git_ignore_path)
  append_to_file git_ignore_path do
    "\n"                   +
    "/public/packs\n"      +
    "/public/packs-test\n" +
    "/node_modules\n"      +
    "/yarn-error.log\n"    +
    "yarn-debug.log*\n"    +
    ".yarn-integrity\n"
  end
end

if (app_layout_path = Rails.root.join("app/views/layouts/application.html.erb")).exist?
  say "Add JavaScript include tag in application layout"
  insert_into_file app_layout_path.to_s, %(\n    <%= javascript_pack_tag "application" %>), before: /\s*<\/head>/
else
  say "Default application.html.erb is missing!", :red
  say %(        Add <%= javascript_pack_tag "application" %> within the <head> tag in your custom layout.)
end

# setup the package manager with default values
@package_json.merge! do |pj|
  package_manager = pj.fetch("packageManager") do
    "#{Shakapacker::Utils::Manager.guess_binary}@#{Shakapacker::Utils::Manager.guess_version}"
  end

  {
    "name" => "app",
    "private" => true,
    "version" => "0.1.0",
    "browserslist" => [
      "defaults"
    ],
    "packageManager" => package_manager
  }.merge(pj)
end

Shakapacker::Utils::Manager.error_unless_package_manager_is_obvious!

# Ensure there is `system!("bin/yarn")` command in `./bin/setup` file
if (setup_path = Rails.root.join("bin/setup")).exist?
  native_install_command = @package_json.manager.native_install_command.join(" ")

  say "Run #{native_install_command} during bin/setup"

  if File.read(setup_path).match? Regexp.escape("  # system('bin/yarn')\n")
    gsub_file(setup_path, "# system('bin/yarn')", "system!('#{native_install_command}')")
  else
    # Due to the inconsistency of quotation usage in Rails 7 compared to
    # earlier versions, we check both single and double quotations here.
    pattern = /system\(['"]bundle check['"]\) \|\| system!\(['"]bundle install['"]\)\n/

    string_to_add = <<-RUBY

  # Install JavaScript dependencies
  system!("#{native_install_command}")
    RUBY

    if File.read(setup_path).match? pattern
      insert_into_file(setup_path, string_to_add, after: pattern)
    else
      say <<~MSG, :red
        It seems your `bin/setup` file doesn't have the expected content.
        Please review the file and manually add `system!("#{native_install_command}")` before any
        other command that requires JavaScript dependencies being already installed.
      MSG
    end
  end
end

Dir.chdir(Rails.root) do
  npm_version = Shakapacker::Utils::VersionSyntaxConverter.new.rubygem_to_npm(Shakapacker::VERSION)
  shakapacker_dependency_value = nil

  # In CI, use the pre-packed tarball if available
  if ENV["SHAKAPACKER_NPM_PACKAGE"]
    package_path = ENV["SHAKAPACKER_NPM_PACKAGE"]

    # Validate package path to prevent directory traversal and invalid file types
    begin
      # Resolve to absolute path
      absolute_path = File.expand_path(package_path)

      # Reject paths containing directory traversal
      if package_path.include?("..") || absolute_path.include?("..")
        say "❌ Security Error: Package path contains directory traversal: #{package_path}", :red
        exit 1
      end

      # Ensure filename ends with .tgz or .tar.gz
      unless absolute_path.end_with?(".tgz", ".tar.gz")
        say "❌ Security Error: Package must be a .tgz or .tar.gz file: #{package_path}", :red
        exit 1
      end

      # Check existence only after validation
      if File.exist?(absolute_path)
        say "📦 Installing shakapacker from local package: #{absolute_path}", :cyan
        begin
          @package_json.manager.add!([absolute_path], type: :production)
          shakapacker_dependency_value = absolute_path
        rescue PackageJson::Error
          say "Shakapacker installation failed 😭 See above for details.", :red
          exit 1
        end
      else
        say "⚠️  SHAKAPACKER_NPM_PACKAGE set but file not found: #{absolute_path}", :yellow
        say "Falling back to npm registry...", :yellow
        begin
          @package_json.manager.add!(["shakapacker@#{npm_version}"], type: :production)
          shakapacker_dependency_value = npm_version
        rescue PackageJson::Error
          say "Shakapacker installation failed 😭 See above for details.", :red
          exit 1
        end
      end
    rescue => e
      say "❌ Error validating package path: #{e.message}", :red
      exit 1
    end
  else
    say "Installing shakapacker@#{npm_version}"
    begin
      @package_json.manager.add!(["shakapacker@#{npm_version}"], type: :production)
      shakapacker_dependency_value = npm_version
    rescue PackageJson::Error
      say "Shakapacker installation failed 😭 See above for details.", :red
      exit 1
    end
  end

  @package_json.merge! do |pj|
    if pj["dependencies"] && pj["dependencies"]["shakapacker"]
      {
        "dependencies" => pj["dependencies"].merge({
          # Keep package.json aligned with the exact source/version this installer requested.
          "shakapacker" => shakapacker_dependency_value || pj["dependencies"]["shakapacker"].delete_prefix("^")
        })
      }
    else
      pj
    end
  end

  # Inline fetch_peer_dependencies and fetch_common_dependencies
  peers = PackageJson.read(install_dir).fetch(ENV["SHAKAPACKER_ASSETS_BUNDLER"] || "webpack")
  common_deps = Shakapacker::Install::Env.truthy_env?("SKIP_COMMON_LOADERS") ? {} : PackageJson.read(install_dir).fetch("common")
  peers = peers.merge(common_deps)

  # Add transpiler-specific dependencies based on detected/configured transpiler
  # Inline the logic here since methods can't be called before they're defined in Rails templates

  # Install transpiler-specific dependencies
  if @transpiler_to_install == "babel"
    # Install babel packages
    babel_deps = PackageJson.read(install_dir).fetch("babel")
    peers = peers.merge(babel_deps)

    # Also install SWC only when USE_BABEL_PACKAGES requested compatibility mode.
    if @install_swc_compat_packages
      swc_deps = PackageJson.read(install_dir).fetch("swc")
      peers = peers.merge(swc_deps)

      say "ℹ️  Installing both Babel and SWC packages for compatibility:", :blue
      say "   - Babel packages are installed as requested via USE_BABEL_PACKAGES", :blue
      say "   - SWC packages are also installed to ensure the default config works", :blue
      say "   - Your actual transpiler will be determined by your shakapacker.yml configuration", :blue
    end
  elsif @transpiler_to_install == "swc"
    swc_deps = PackageJson.read(install_dir).fetch("swc")
    peers = peers.merge(swc_deps)
  elsif @transpiler_to_install == "esbuild"
    esbuild_deps = PackageJson.read(install_dir).fetch("esbuild")
    peers = peers.merge(esbuild_deps)
  end

  dev_dependency_packages = ["webpack-dev-server"]

  dependencies_to_add = []
  dev_dependencies_to_add = []

  peers.each do |(package, version)|
    # Handle versions like "^1.3.0" or ">= 4 || 5"
    if version.start_with?("^", "~") || version.match?(/^\d+\.\d+/)
      # Already has proper version format, use as-is
      entry = "#{package}@#{version}"
    else
      # Extract major version from complex version strings like ">= 4 || 5"
      # Fallback to "latest" if no version number found
      version_match = version.split("||").last.match(/(\d+)/)
      major_version = version_match ? version_match[1] : "latest"
      entry = "#{package}@#{major_version}"
    end

    if dev_dependency_packages.include? package
      dev_dependencies_to_add << entry
    else
      dependencies_to_add << entry
    end
  end

  say "Adding shakapacker peerDependencies"
  begin
    @package_json.manager.add!(dependencies_to_add, type: :production)
  rescue PackageJson::Error
    say "Shakapacker installation failed 😭 See above for details.", :red
    exit 1
  end

  say "Installing webpack-dev-server for live reloading as a development dependency"
  begin
    @package_json.manager.add!(dev_dependencies_to_add, type: :dev)
  rescue PackageJson::Error
    say "Shakapacker installation failed 😭 See above for details.", :red
    exit 1
  end

  # Configure babel preset in package.json if babel is being used
  if @transpiler_to_install == "babel"
    @package_json.merge! do |pj|
      babel = pj.fetch("babel", {})
      babel["presets"] ||= []
      unless babel["presets"].include?("./node_modules/shakapacker/package/babel/preset.js")
        babel["presets"].push("./node_modules/shakapacker/package/babel/preset.js")
      end
      { "babel" => babel }
    end
  end
end

# Helper methods defined at the end (Rails template convention)

def package_json
  @package_json
end
