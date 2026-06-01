# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'minitest/test_task'
require 'rdoc/task'
require 'rubocop/rake_task'

task default: :test

Minitest::TestTask.create do |test|
  test.framework = 'require "simplecov"'
  test.test_globs = 'test/**/*_test.rb'
end

RDoc::Task.new do |rdoc|
  rdoc.main = 'README.md'
  rdoc.rdoc_files.include('README.md', 'lib/**/*.rb')
  rdoc.options << '--markup=markdown'
  rdoc.options << '--tab-width=2'
  rdoc.options << "-t Rubyzip version #{Zip::VERSION}"
end

RuboCop::RakeTask.new
