namespace :shakapacker do
  desc "Verifies if the Shakapacker config is present"
  task :verify_config do
    unless Shakapacker.config.config_path.exist?
      path = Shakapacker.config.config_path.relative_path_from(Pathname.new(pwd)).to_s
      $stderr.puts "Configuration #{path} file not found. \n"\
           "Make sure shakapacker:install is run successfully before " \
           "running dependent tasks"
      exit!
    end
  end
end
