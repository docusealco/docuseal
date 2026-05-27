require "shakapacker/utils/misc"
require "shakapacker/utils/manager"

namespace :shakapacker do
  desc "Verifies if the expected JS package manager is installed"
  task :check_manager do
    Shakapacker::Utils::Manager.error_unless_package_manager_is_obvious!

    package_json = PackageJson.read
    pm = package_json.manager.binary

    begin
      version = package_json.manager.version

      $stdout.puts "using #{pm}@#{version} to manage dependencies and scripts in package.json"
    rescue PackageJson::Error
      $stderr.puts "#{pm} not installed - please ensure it is installed before trying again"
      $stderr.puts "Exiting!"
      exit!
    end
  end
end
