require 'rubygems'

require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  warn e.message
  warn 'Run `bundle install` to install missing gems'
  exit e.status_code
end

require 'juwelier'
Juwelier::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://docs.rubygems.org/read/chapter/20 for more options
  gem.name = 'rubyXL'
  gem.homepage = 'http://github.com/gilt/rubyXL'
  gem.license = 'MIT'
  gem.summary = %q{rubyXL is a gem which allows the parsing, creation, and manipulation of Microsoft Excel (.xlsx/.xlsm) Documents}
  gem.description = %q{rubyXL is a gem which allows the parsing, creation, and manipulation of Microsoft Excel (.xlsx/.xlsm) Documents}
  gem.email = 'bhagwat.vivek@gmail.com'
  gem.authors = ['Vivek Bhagwat', 'Wesha']
#  gem.required_ruby_version = '>2.1'
  # dependencies defined in Gemfile
end
Juwelier::RubygemsDotOrgTasks.new

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true
  test.warning = true
end

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:rspec)
task :default => :rspec

require 'rdoc/task'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ''

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "rubyXL #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

desc 'Dump profiling data with stackprof'
task :stackprof do
  require 'benchmark'
  require 'stackprof'

  $LOAD_PATH.unshift File.dirname(__FILE__) + '/lib'  # Make Ruby aware of load path
  require './lib/rubyXL'

  spreadsheets = Dir.glob(File.join('test', 'input', '*.xls?')).sort!

  spreadsheets.each { |input|
    puts "<<<--- Profiling parsing of #{input}..."
    doc = nil
    StackProf.run(:mode => :cpu, :interval => 100,
                  :out  => "tmp/stackprof-cpu-parse-#{File.basename(input)}.dump") {
      doc = RubyXL::Parser.parse(input)
    }

    output = File.join('test', 'output', File.basename(input))
    puts "--->>> Profiling writing of #{output}..."
    StackProf.run(:mode => :cpu, :interval => 100,
                  :out  => "tmp/stackprof-cpu-write-#{File.basename(input)}.dump") {
      doc.write(output)
    }
  }
end

desc 'Dump profiling data with ruby-prof'
task :rubyprof do
  require 'benchmark'
  require 'ruby-prof'

  $LOAD_PATH.unshift File.dirname(__FILE__) + '/lib'  # Make Ruby aware of load path
  require './lib/rubyXL'

  spreadsheets = Dir.glob(File.join('test', 'input', '*.xls?')).sort!

  spreadsheets.each { |input|
    puts "<<<--- Profiling parsing of #{input}..."
    doc = nil
    result = RubyProf.profile {
      doc = RubyXL::Parser.parse(input)
    }
    printer = RubyProf::CallStackPrinter.new(result)
    File.open("tmp/ruby-prof-parse-#{File.basename(input)}.html", 'w') { |f| printer.print(f, {}) }

    output = File.join('test', 'output', File.basename(input))
    puts "--->>> Profiling writing of #{output}..."
    result = RubyProf.profile {
      doc.write(output)
    }
    printer = RubyProf::CallStackPrinter.new(result)
    File.open("tmp/ruby-prof-write-#{File.basename(input)}.html", 'w') { |f| printer.print(f, {}) }
  }
end
