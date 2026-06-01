# encoding: utf-8

# Copyright 2010-2013 Ayumu Nojima (野島 歩) and Martin J. Dürst (duerst@it.aoyama.ac.jp)
# available under the same licence as Ruby itself
# (see http://www.ruby-lang.org/en/LICENSE.txt)

ROOT_DIR = Pathname.new(File.join(File.dirname(__FILE__)))
$:.push(ROOT_DIR.to_s)

require 'eprun/helpers'
require 'tasks/erb_template'
require 'tasks/tables_generator'

require 'rubygems/package_task'

task :default => :test
Bundler::GemHelper.install_tasks

task :test do
  require 'test/unit'
  files = Dir.glob("./test/test_*.rb")
  runner = Test::Unit::AutoRunner.new(true)
  runner.process_args(files)
  runner.run
end

task :generate_tables do
  EprunTasks::TablesGenerator.new(
    ROOT_DIR.join("data").to_s,
    ROOT_DIR.join("lib", Eprun.require_path).to_s
  ).generate
end

task :benchmark do
  require 'eprun'
  require ROOT_DIR.join("benchmark/benchmark").to_s

  Eprun.enable_core_extensions!
  EprunTasks::Benchmarks.new(ROOT_DIR.join("benchmark".to_s)).run
end