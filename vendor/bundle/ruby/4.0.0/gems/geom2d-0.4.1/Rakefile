# frozen_string_literal: true

require 'rake/testtask'
require 'rake/clean'
require 'rubygems/package_task'

$:.unshift('lib')
require 'geom2d/version'

Rake::TestTask.new do |t|
  t.libs << 'test'
  t.test_files = FileList['test/**/*.rb']
  t.verbose = false
  t.warning = true
end

namespace :dev do
  PKG_FILES = FileList.new(
    [
      'README.md',
      'lib/**/*.rb',
      'test/**/*',
      'Rakefile',
      'CHANGELOG.md',
      'LICENSE',
      'VERSION',
      'CONTRIBUTERS',
    ]
  )

  CLOBBER << "VERSION"
  file 'VERSION' do
    puts "Generating VERSION file"
    File.open('VERSION', 'w+') {|file| file.write(Geom2D::VERSION + "\n") }
  end

  CLOBBER << 'CONTRIBUTERS'
  file 'CONTRIBUTERS' do
    puts "Generating CONTRIBUTERS file"
    `echo "  Count Name" > CONTRIBUTERS`
    `echo "======= ====" >> CONTRIBUTERS`
    `git log | grep ^Author: | sed 's/^Author: //' | sort | uniq -c | sort -nr >> CONTRIBUTERS`
  end

  spec = Gem::Specification.new do |s|
    s.name = 'geom2d'
    s.version = Geom2D::VERSION
    s.summary = "Objects and Algorithms for 2D Geometry"
    s.license = 'MIT'

    s.files = PKG_FILES.to_a

    s.require_path = 'lib'
    s.required_ruby_version = '>= 2.6'
    s.add_development_dependency('rubocop', '~> 1.0', '>= 1.41.1')

    s.author = 'Thomas Leitner'
    s.email = 't_leitner@gmx.at'
    s.homepage = "https://geom2d.gettalong.org"
  end

  Gem::PackageTask.new(spec) do |pkg|
    pkg.need_zip = true
    pkg.need_tar = true
  end

  desc "Upload the release to Rubygems"
  task publish_files: [:package] do
    sh "gem push pkg/geom2d-#{Geom2D::VERSION}.gem"
    puts 'done'
  end

  desc 'Release Geom2D version ' + Geom2D::VERSION
  task release: [:clobber, :package, :publish_files]

  desc "Insert/Update copyright notice"
  task :update_copyright do
    statement = <<~STATEMENT
      #--
      # geom2d - 2D Geometric Objects and Algorithms
      # Copyright (C) 2018-2023 Thomas Leitner <t_leitner@gmx.at>
      #
      # This software may be modified and distributed under the terms
      # of the MIT license.  See the LICENSE file for details.
      #++
    STATEMENT
    state_re = /\A(#.*\n)*#{Regexp.escape(statement)}/
    inserted = false
    Dir["lib/**/*.rb"].each do |file|
      unless File.read(file).match?(state_re)
        inserted = true
        puts "Updating file #{file}"
        old = File.read(file)
        old.sub!(/^#--.*?\n#\+\+\n/m, statement)
        File.write(file, old)
      end
    end
    puts "Look through the above mentioned files and correct all problems" if inserted
  end
end

task clobber: 'dev:clobber'
task default: 'test'
