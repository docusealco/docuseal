# -*- ruby -*-
#
#--
# cmdparse: advanced command line parser supporting commands
# Copyright (C) 2004-2015 Thomas Leitner
#
# This file is part of cmdparse which is licensed under the MIT.
#++
#

require 'rubygems/package_task'
require 'rake/clean'
require 'rake/packagetask'
require 'rdoc/task'

# General actions  ##############################################################

$:.unshift 'lib'
require 'cmdparse'

PKG_NAME = "cmdparse"
PKG_VERSION = CmdParse::VERSION
PKG_FULLNAME = PKG_NAME + "-" + PKG_VERSION

begin
  require 'webgen/page'
rescue LoadError
end

# End user tasks ################################################################

# The default task is run if rake is given no explicit arguments.
task :default do
  puts "Select task to execute:"
  sh "rake -T"
end

desc "Installs the package #{PKG_NAME} using setup.rb"
task :install do
  ruby "setup.rb config"
  ruby "setup.rb setup"
  ruby "setup.rb install"
end

task :clean do
  ruby "setup.rb clean"
end

desc "Build the whole user documentation (website and api)"
task :doc

if defined?(Webgen)
  CLOBBER << "htmldoc"
  CLOBBER << "webgen-tmp"

  desc "Builds the documentation website"
  task :htmldoc do
    sh "webgen"
  end
  task :doc => :htmldoc
end

# Developer tasks ##############################################################

namespace :dev do

  PKG_FILES = FileList.new( [
                             'setup.rb',
                             'COPYING',
                             'README.md',
                             'Rakefile',
                             'example/net.rb',
                             'VERSION',
                             'lib/**/*.rb',
                             'doc/**/*',
                             'webgen.config'
                            ])

  CLOBBER << "VERSION"
  file 'VERSION' do
    puts "Generating VERSION file"
    File.open('VERSION', 'w+') {|file| file.write(PKG_VERSION + "\n")}
  end

  Rake::PackageTask.new('cmdparse', PKG_VERSION) do |pkg|
    pkg.need_tar = true
    pkg.need_zip = true
    pkg.package_files = PKG_FILES
  end

  spec = Gem::Specification.new do |s|

    #### Basic information
    s.name = PKG_NAME
    s.version = PKG_VERSION
    s.summary = "Advanced command line parser supporting commands"
    s.description = <<-EOF
       cmdparse provides classes for parsing (possibly nested) commands on the command line;
       command line options themselves are parsed using optparse.
       EOF
    s.license = 'MIT'

    #### Dependencies, requirements and files
    s.files = PKG_FILES.to_a
    s.require_path = 'lib'
    s.required_ruby_version = ">= 2.0.0"
    s.add_development_dependency "webgen", "~> 1.4"

    #### Documentation
    s.rdoc_options = ['--line-numbers', '--main', 'CmdParse::CommandParser']

    #### Author and project details
    s.author = "Thomas Leitner"
    s.email = "t_leitner@gmx.at"
    s.homepage = "https://cmdparse.gettalong.org"
  end

  Gem::PackageTask.new(spec) do |pkg|
    pkg.need_zip = true
    pkg.need_tar = true
  end

  desc "Upload the release to Rubygems"
  task :publish_files => [:package] do
    sh "gem push pkg/cmdparse-#{PKG_VERSION}.gem"
  end

  if defined?(Webgen)
    desc "Release cmdparse version " + PKG_VERSION
    task :release => [:clobber, :package, :publish_files, :doc] do
      puts "Upload htmldoc/ to the webserver"
    end
  end

end

task :clobber => ['dev:clobber']
