install_template_path = File.expand_path("../../install/template.rb", __dir__).freeze
bin_path = ENV["BUNDLE_BIN"] || Rails.root.join("bin")

namespace :shakapacker do
  desc "Install Shakapacker in this application (use SHAKAPACKER_ASSETS_BUNDLER=rspack for Rspack, --typescript for TypeScript)"
  task :install, [:bundler, :typescript] => [:check_node] do |task, args|
    Shakapacker::Configuration.installing = true

    if args[:bundler] == "rspack" || ENV["SHAKAPACKER_ASSETS_BUNDLER"] == "rspack"
      ENV["SHAKAPACKER_ASSETS_BUNDLER"] = "rspack"
    end

    # Set typescript flag if passed as argument
    # Accepts: typescript, true, or any truthy value
    if args[:typescript] && args[:typescript] != "false"
      ENV["SHAKAPACKER_USE_TYPESCRIPT"] = "true"
    end

    prefix = task.name.split(/#|shakapacker:install/).first

    if Rails::VERSION::MAJOR >= 5
      system "#{RbConfig.ruby} '#{bin_path}/rails' #{prefix}app:template LOCATION='#{install_template_path}'" or
        raise "Installation failed"
    else
      system "#{RbConfig.ruby} '#{bin_path}/rake' #{prefix}rails:template LOCATION='#{install_template_path}'" or
        raise "Installation failed"
    end
  end
end
