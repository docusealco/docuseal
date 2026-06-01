require "shakapacker/swc_migrator"

namespace :shakapacker do
  desc "Migrate from Babel to SWC transpiler"
  task :migrate_to_swc do
    Shakapacker::SwcMigrator.new(Rails.root).migrate_to_swc
  end

  desc "Remove Babel packages after migrating to SWC"
  task :clean_babel_packages do
    Shakapacker::SwcMigrator.new(Rails.root).clean_babel_packages
  end
end
