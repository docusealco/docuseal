tasks = {
  "shakapacker:info"                    => "Provides information on Shakapacker's environment",
  "shakapacker:install"                 => "Installs and setup webpack",
  "shakapacker:compile"                 => "Compiles webpack bundles based on environment",
  "shakapacker:clean"                   => "Remove old compiled bundles",
  "shakapacker:clobber"                 => "Removes the webpack compiled output directory",
  "shakapacker:check_node"              => "Verifies if Node.js is installed",
  "shakapacker:check_manager"           => "Verifies if the expected JS package manager is available",
  "shakapacker:check_binstubs"          => "Verifies that bin/shakapacker is present",
  "shakapacker:binstubs"                => "Installs Shakapacker binstubs in this application",
  "shakapacker:verify_install"          => "Verifies if Shakapacker is installed",
  "shakapacker:doctor"                  => "Checks for configuration issues and missing dependencies",
  "shakapacker:switch_bundler"          => "Switch between webpack and rspack bundlers"
}.freeze

desc "Lists all available tasks in Shakapacker"
task :shakapacker do
  puts "Available Shakapacker tasks are:"
  tasks.each { |task, message| puts task.ljust(30) + message }
end
