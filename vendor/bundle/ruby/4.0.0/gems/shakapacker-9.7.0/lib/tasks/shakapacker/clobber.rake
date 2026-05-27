require "shakapacker/configuration"

namespace :shakapacker do
  desc "Remove the webpack compiled output directory"
  task clobber: ["shakapacker:verify_config", :environment] do
    Shakapacker.clobber
    $stdout.puts "Removed webpack output path directory #{Shakapacker.config.public_output_path}"
  end
end

if Shakapacker.config.shakapacker_precompile?
  # Run clobber if the assets:clobber is run
  if Rake::Task.task_defined?("assets:clobber")
    Rake::Task["assets:clobber"].enhance do
      Rake::Task["shakapacker:clobber"].invoke
    end
  end
end
