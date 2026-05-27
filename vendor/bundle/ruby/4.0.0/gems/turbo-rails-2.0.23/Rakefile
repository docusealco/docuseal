require "bundler/setup"
require "bundler/gem_tasks"
require "rake/testtask"

APP_RAKEFILE = File.expand_path("test/dummy/Rakefile", __dir__)
load "rails/tasks/engine.rake"
load "rails/tasks/statistics.rake"

Rake::TestTask.new do |test|
  test.libs << "test"
  test.test_files = FileList["test/**/*_test.rb"]
end

task :test_prereq do
  puts "Installing Ruby dependencies"
  `bundle install`

  puts "Installing JavaScript dependencies"
  `yarn install`

  puts "Building JavaScript"
  `yarn build`

  puts "Preparing test database"
  `cd test/dummy; ./bin/rails db:test:prepare; cd ../..`
end

task default: [:test_prereq, :test]
