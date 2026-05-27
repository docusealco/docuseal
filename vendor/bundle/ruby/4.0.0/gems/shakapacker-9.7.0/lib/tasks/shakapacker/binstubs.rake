binstubs_template_path = File.expand_path("../../install/binstubs.rb", __dir__).freeze
bin_path = ENV["BUNDLE_BIN"] || Rails.root.join("bin")

namespace :shakapacker do
  desc "Installs Shakapacker binstubs in this application"
  task binstubs: [:check_node, :check_manager] do |task|
    prefix = task.name.split(/#|shakapacker:binstubs/).first

    if Rails::VERSION::MAJOR >= 5
      system "#{RbConfig.ruby} '#{bin_path}/rails' #{prefix}app:template LOCATION='#{binstubs_template_path}'" or
        raise "Binstubs installation failed"
    else
      system "#{RbConfig.ruby} '#{bin_path}/rake' #{prefix}rails:template LOCATION='#{binstubs_template_path}'" or
        raise "Binstubs installation failed"
    end
  end
end
