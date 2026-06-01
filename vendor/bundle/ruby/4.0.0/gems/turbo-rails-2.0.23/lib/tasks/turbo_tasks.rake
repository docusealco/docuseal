module Turbo
  module Tasks
    extend self
    def run_turbo_install_template(path)
      system "#{RbConfig.ruby} ./bin/rails app:template LOCATION=#{File.expand_path("../install/#{path}.rb", __dir__)}"
    end

    def using_bun?
      Rails.root.join("bun.config.js").exist?
    end
  end
end

namespace :turbo do
  desc "Install Turbo into the app"
  task :install do
    if Rails.root.join("config/importmap.rb").exist?
      Rake::Task["turbo:install:importmap"].invoke
    elsif Rails.root.join("package.json").exist? && Turbo::Tasks.using_bun?
      Rake::Task["turbo:install:bun"].invoke
    elsif Rails.root.join("package.json").exist?
      Rake::Task["turbo:install:node"].invoke
    else
      puts "You must either be running with node (package.json) or importmap-rails (config/importmap.rb) to use this gem."
    end
  end

  namespace :install do
    desc "Install Turbo into the app with asset pipeline"
    task :importmap do
      Turbo::Tasks.run_turbo_install_template "turbo_with_importmap"
    end

    desc "Install Turbo into the app with webpacker"
    task :node do
      Turbo::Tasks.run_turbo_install_template "turbo_with_node"
    end

    desc "Install Turbo into the app with bun"
    task :bun do
      Turbo::Tasks.run_turbo_install_template "turbo_with_bun"
    end
  end
end
