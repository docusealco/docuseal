# frozen_string_literal: true
require "bundler/gem_tasks"
require "pathname"

# Remove Bundler's default `release` task — it bypasses the custom release flow
# (CHANGELOG version detection, npm publish, GitHub release sync, etc.).
# The custom `release` task in rakelib/release.rake replaces it.
Rake::Task[:release].clear

desc "Run all specs"
task test: ["run_spec:all_specs"]

task default: :test

namespace :run_spec do
  desc "Run shakapacker specs"
  task :gem do
    puts "Running Shakapacker gem specs"
    sh("bundle exec rspec spec/shakapacker/*_spec.rb")
  end

  desc "Run specs in the dummy app with webpack"
  task :dummy do
    puts "Running dummy app specs with webpack"
    spec_dummy_dir = Pathname.new(File.join("spec", "dummy")).realpath
    Bundler.with_unbundled_env do
      sh_in_dir(".", "yalc publish")
      sh_in_dir(spec_dummy_dir, [
        "bundle install",
        "yalc link shakapacker",
        "npm install",
        "bin/test-bundler webpack",
        "NODE_ENV=test RAILS_ENV=test bin/shakapacker",
        "bundle exec rspec"
      ])
    end
  end

  desc "Run specs in the dummy app with rspack"
  task :dummy_with_rspack do
    puts "Running dummy app specs with rspack"
    spec_dummy_dir = Pathname.new(File.join("spec", "dummy")).realpath
    Bundler.with_unbundled_env do
      sh_in_dir(".", "yalc publish")
      sh_in_dir(spec_dummy_dir, [
        "bundle install",
        "yalc link shakapacker",
        "npm install",
        "bin/test-bundler rspack",
        "NODE_ENV=test RAILS_ENV=test bin/shakapacker",
        "bundle exec rspec"
      ])
    end
  end

  desc "Run specs in the dummy-rspack app"
  task :dummy_rspack do
    puts "Running dummy-rspack app specs"
    spec_dummy_dir = Pathname.new(File.join("spec", "dummy-rspack")).realpath
    Bundler.with_unbundled_env do
      sh_in_dir(".", "yalc publish")
      sh_in_dir(spec_dummy_dir, [
        "bundle install",
        "yalc link shakapacker",
        "npm install",
        "NODE_ENV=test RAILS_ENV=test npm exec --no -- rspack build --config config/rspack/rspack.config.js",
        "bundle exec rspec"
      ])
    end
  end

  desc "Run generator specs"
  task :generator do
    sh("bundle exec rspec spec/generator_specs/*_spec.rb")
  end

  desc "Run all specs"
  task all_specs: %i[gem dummy dummy_with_rspack dummy_rspack generator] do
    puts "Completed all RSpec tests"
  end
end

def sh_in_dir(dir, *shell_commands)
  Shakapacker::Utils::Misc.sh_in_dir(dir, *shell_commands)
end
