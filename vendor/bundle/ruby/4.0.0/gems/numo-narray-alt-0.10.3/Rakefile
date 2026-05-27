# frozen_string_literal: true

require 'bundler/gem_tasks'

task :doc do
  dir = 'ext/numo/narray'
  src = %w[array.c data.c index.c math.c narray.c rand.c struct.c]
        .map { |s| File.join(dir, s) } +
        [File.join(dir, 't_*.c'), 'lib/numo/narray/extra.rb']
  sh 'cd ext/numo/narray; ruby extconf.rb; make src'
  sh "rm -rf yard .yardoc; yard doc -o yard -m markdown -r README.md #{src.join(' ')}"
end

task :'clang-format' do
  sh 'bash -c "shopt -s globstar && clang-format -style=file -Werror --dry-run ext/numo/narray/**/*.{c,h}"' do |ok, _res|
    puts 'clang-format violations found, here is the autofix command: clang-format --style=file -i ...' unless ok
  end
end

require 'ruby_memcheck' if ENV['BUNDLE_WITH'] == 'memcheck'
require 'rake/testtask'

if ENV['BUNDLE_WITH'] == 'memcheck'
  test_config = lambda do |t|
    t.libs << 'test'
    t.libs << 'lib'
    t.test_files = FileList['test/**/test_*.rb']
  end
  Rake::TestTask.new(test: :compile, &test_config)
  namespace :test do
    RubyMemcheck::TestTask.new(valgrind: :compile, &test_config)
  end
else
  Rake::TestTask.new(:test) do |t|
    t.libs << 'test'
    t.libs << 'lib'
    t.test_files = FileList['test/**/test_*.rb']
  end
end

require 'rake/extensiontask'

GEMSPEC = Gem::Specification.load('numo-narray-alt.gemspec')

Rake::ExtensionTask.new('numo/narray', GEMSPEC) do |ext|
  ext.ext_dir = 'ext/numo/narray'
  ext.lib_dir = 'lib/numo/narray'
end

task default: %i[clobber compile test]
