require "shakapacker/bundler_switcher"

namespace :shakapacker do
  desc <<~DESC
    Switch between webpack and rspack bundlers

    Easily switch your Shakapacker configuration between webpack and rspack bundlers.
    This task updates config/shakapacker.yml and optionally manages npm dependencies.

    Usage:
      bin/rake shakapacker:switch_bundler [webpack|rspack] -- [OPTIONS]

    Options:
      --install-deps    Automatically install/uninstall bundler dependencies
      --no-uninstall    Skip uninstalling old bundler packages
      --init-config     Create custom dependencies configuration file
      --help, -h        Show detailed help message

    Examples:
      bin/rake shakapacker:switch_bundler rspack -- --install-deps
      bin/rake shakapacker:switch_bundler webpack -- --install-deps --no-uninstall
      bin/rake shakapacker:switch_bundler -- --init-config
      bin/rake shakapacker:switch_bundler -- --help

    What it does:
      - Updates 'assets_bundler' in config/shakapacker.yml
      - Preserves YAML comments and structure
      - Updates 'javascript_transpiler' to 'swc' when switching to rspack
      - With --install-deps: installs/uninstalls npm dependencies automatically
      - Without: shows manual installation commands

    Custom Dependencies:
      Create .shakapacker-switch-bundler-dependencies.yml to customize which
      npm packages are installed/uninstalled during bundler switching.

    See docs/rspack_migration_guide.md for more information.
  DESC
  task :switch_bundler do
    # This task must be run with rake, not rails
    # Check the actual command name, not just if the path contains "rails"
    command_name = File.basename($0)
    if command_name == "rails" || $0.end_with?("/rails")
      puts "\nError: This task must be run with 'bin/rake', not 'bin/rails'"
      puts "Usage: bin/rake shakapacker:switch_bundler [bundler] -- [options]"
      puts "Run 'bin/rake shakapacker:switch_bundler -- --help' for more information"
      exit 1
    end

    switcher = Shakapacker::BundlerSwitcher.new

    # Parse command line arguments
    # ARGV[0] is the task name, ARGV[1] would be the bundler name if provided
    bundler = ARGV.length > 1 ? ARGV[1] : nil
    install_deps = ARGV.include?("--install-deps")
    no_uninstall = ARGV.include?("--no-uninstall")
    init_config = ARGV.include?("--init-config")
    show_help = ARGV.include?("--help") || ARGV.include?("-h")

    if ARGV.empty? || show_help || (bundler.nil? && !init_config)
      switcher.show_usage
    elsif init_config
      switcher.init_config
    elsif bundler.nil? || bundler.start_with?("-")
      switcher.show_usage
    else
      switcher.switch_to(bundler, install_deps: install_deps, no_uninstall: no_uninstall)
    end

    # Prevent rake from trying to execute arguments as tasks
    ARGV.each { |arg| task arg.to_sym {} }
  end
end
