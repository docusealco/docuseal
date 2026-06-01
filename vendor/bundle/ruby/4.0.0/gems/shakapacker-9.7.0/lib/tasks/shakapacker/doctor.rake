require "shakapacker/doctor"

namespace :shakapacker do
  desc <<~DESC
    Checks for common Shakapacker configuration issues and missing dependencies

    Performs comprehensive diagnostics including:
    • Configuration file validity and deprecated settings
    • Entry points, output paths, and asset compilation status
    • Node.js and package manager installation
    • Required and optional npm dependencies
    • JavaScript transpiler (Babel, SWC, esbuild) configuration
    • CSS, CSS Modules, and stylesheet preprocessor setup
    • Binstubs presence (shakapacker, shakapacker-dev-server, shakapacker-config)
    • Version consistency between gem and npm package
    • Legacy Webpacker file detection

    Options:
      --help       Show detailed help and usage information
      --verbose    Display additional diagnostic details (paths, versions, environment)

    Examples:
      bundle exec rake shakapacker:doctor
      bundle exec rake shakapacker:doctor -- --verbose
      bundle exec rake shakapacker:doctor -- --help

    Exit codes:
      0 - No issues found
      1 - Issues or warnings detected (see output for details)
  DESC
  task doctor: :environment do
    # Parse command-line options
    options = {}
    ARGV.each do |arg|
      case arg
      when "--help", "-h"
        options[:help] = true
      when "--verbose", "-v"
        options[:verbose] = true
      end
    end

    Shakapacker::Doctor.new(nil, nil, options).run

    # Prevent rake from treating options as task names
    ARGV.each { |arg| task arg.to_sym do; end if arg.start_with?("--", "-") }
  end
end
