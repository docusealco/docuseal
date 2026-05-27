# -*- coding: utf-8 -*-
require 'rake/testtask'
require 'rake/clean'
require 'rubygems/package_task'

require_relative 'lib/hexapdf/version'

Rake::TestTask.new do |t|
  t.libs << 'test'
  t.test_files = FileList['test/**/*.rb']
  t.verbose = false
  t.warning = true
end

namespace :dev do
  CLOBBER << "man/man1/hexapdf.1"
  file 'man/man1/hexapdf.1' => ['man/man1/hexapdf.1.md'] do
    puts "Generating hexapdf man page"
    system "kramdown -o man man/man1/hexapdf.1.md > man/man1/hexapdf.1"
  end

  CLOBBER << "VERSION"
  file 'VERSION' do
    puts "Generating VERSION file"
    File.open('VERSION', 'w+') {|file| file.write(HexaPDF::VERSION + "\n") }
  end

  CLOBBER << 'CONTRIBUTERS'
  file 'CONTRIBUTERS' do
    puts "Generating CONTRIBUTERS file"
    `echo "  Count Name" > CONTRIBUTERS`
    `echo "======= ====" >> CONTRIBUTERS`
    `git log | grep ^Author: | sed 's/^Author: //' | sort | uniq -c | sort -nr >> CONTRIBUTERS`
  end

  ENV['REAL_GEM'] = "true"
  spec = eval(File.read('hexapdf.gemspec'), binding, 'hexapdf.gemspec')
  Gem::PackageTask.new(spec) do |pkg|
    pkg.need_zip = true
    pkg.need_tar = true
  end

  desc "Upload the release to Rubygems"
  task publish_files: [:package] do
    sh "gem push pkg/hexapdf-#{HexaPDF::VERSION}.gem"
    puts 'done'
  end

  task :test_all do
    versions = `rbenv versions --bare | grep -i ^3.`.split("\n")
    versions.each do |version|
      sh "eval \"$(rbenv init -)\"; rbenv shell #{version} && ruby -v && rake test"
    end
    puts "Looks okay? (enter to continue, Ctrl-c to abort)"
    $stdin.gets
  end

  desc 'Release HexaPDF version ' + HexaPDF::VERSION
  task release: [:clobber, :test_all, :package, :publish_files]

  desc "Set-up everything for development"
  task :setup do
    puts "Installing required runtime and development gems:"
    resolver = Gem::Resolver.for_current_gems(spec.dependencies)
    resolver.ignore_dependencies = true
    resolver.soft_missing = true
    resolver.resolve
    spec.dependencies.each do |dependency|
      if resolver.missing.find {|dep_request| dep_request.dependency == dependency }
        print "✗ #{dependency.name} - installing it..."
        Gem.install(dependency.name, dependency.requirement, prerelease: true)
        puts " done"
      else
        puts "✓ #{dependency.name}"
      end
    end

    puts
    puts "The following binaries are needed for the tests:"
    {
      'pngtopnm' => 'sudo apt install netpbm',
      'pngcheck' => 'sudo apt install pngcheck',
    }.each do |name, install_command|
      `which #{name} 2>&1`
      if $?.exitstatus == 0
        puts "✓ #{name}"
      else
        puts "✗ #{name} (#{install_command})"
      end
    end
  end

  CODING_LINE = "# -*- encoding: utf-8; frozen_string_literal: true -*-\n"

  desc "Insert/Update copyright notice"
  task :update_copyright do
    license = File.readlines(File.join(__dir__, 'LICENSE')).map do |l|
      l.strip.empty? ? "#\n" : "# #{l}"
    end.join
    statement = CODING_LINE + "#\n#--\n# This file is part of HexaPDF.\n#\n" + license + "#++\n"
    inserted = false
    Dir["lib/**/*.rb"].each do |file|
      unless File.read(file).start_with?(statement)
        inserted = true
        puts "Updating file #{file}"
        old = File.read(file)
        unless old.gsub!(/\A#{Regexp.escape(CODING_LINE)}#\n#--.*?\n#\+\+\n/m, statement)
          old.gsub!(/\A(#{Regexp.escape(CODING_LINE)})?/, statement)
        end
        File.write(file, old)
      end
    end
    puts "Look through the above mentioned files and correct all problems" if inserted
  end
end

task clobber: 'dev:clobber'
task default: 'test'
