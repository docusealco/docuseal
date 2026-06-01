require 'bundler/gem_tasks'
require 'rake/testtask'

Rake::TestTask.new(:test) do |t|
  t.libs << 'test/lib'
  t.ruby_opts << '-rhelper'
  t.test_files = FileList['test/**/test_*.rb']
end

case RUBY_ENGINE
when 'jruby', 'truffleruby'
  # not using C extension
else
  require 'rake/extensiontask'
  Rake::ExtensionTask.new('erb/escape')
  task test: :compile
end

task default: :test
