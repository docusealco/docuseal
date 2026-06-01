# -*- rake -*-

# Enable english error messages, as some specs depend on them
ENV["LANG"] = "C"

require 'rbconfig'
require 'pathname'
require 'tmpdir'
require 'rake/extensiontask'
require 'rake/clean'
require 'rspec/core/rake_task'
require 'bundler'
require 'bundler/gem_helper'
require_relative "rakelib/pg_gem_helper"

# Build directory constants
BASEDIR = Pathname( __FILE__ ).dirname
SPECDIR = BASEDIR + 'spec'
LIBDIR  = BASEDIR + 'lib'
EXTDIR  = BASEDIR + 'ext'
PKGDIR  = BASEDIR + 'pkg'
TMPDIR  = BASEDIR + 'tmp'
TESTDIR = BASEDIR + "tmp_test_*"

DLEXT   = RbConfig::CONFIG['DLEXT']
EXT     = LIBDIR + "pg_ext.#{DLEXT}"

GEMSPEC = 'pg.gemspec'

CLEAN.include( TESTDIR.to_s )
CLEAN.include( PKGDIR.to_s, TMPDIR.to_s )
CLEAN.include "lib/*/libpq.dll"
CLEAN.include "lib/pg_ext.*"
CLEAN.include "lib/pg/postgresql_lib_path.rb"
CLEAN.include "ports/*.installed"
CLEAN.include "ports/*mingw*", "ports/*linux*", "ports/*darwin*"

PgGemHelper.install_tasks
$gem_spec = Bundler.load_gemspec(GEMSPEC)

desc "Turn on warnings and debugging in the build."
task :maint do
	ENV['MAINTAINER_MODE'] = 'yes'
end

CrossLibrary = Struct.new :platform, :openssl_config, :toolchain
CrossLibraries = [
	['aarch64-mingw-ucrt', 'mingwarm64', 'aarch64-w64-mingw32'],
	['x64-mingw-ucrt', 'mingw64', 'x86_64-w64-mingw32'],
	['x64-mingw32', 'mingw64', 'x86_64-w64-mingw32'],
	['x86_64-linux', 'linux-x86_64', 'x86_64-linux-gnu'],
	['x86_64-linux-musl', 'linux-x86_64', 'x86_64-unknown-linux-musl'],
	['aarch64-linux', 'linux-aarch64', 'aarch64-linux-gnu'],
	['aarch64-linux-musl', 'linux-aarch64', 'aarch64-linux-musl'],
	['x86_64-darwin', 'darwin64-x86_64', 'x86_64-apple-darwin'],
	['arm64-darwin', 'darwin64-arm64', 'arm64-apple-darwin'],
].map do |platform, openssl_config, toolchain|
	CrossLibrary.new platform, openssl_config, toolchain
end

# Register binary gems to be pushed to rubygems.org
Bundler::GemHelper.instance.cross_platforms = CrossLibraries.map(&:platform)

# Rake-compiler task
Rake::ExtensionTask.new do |ext|
	ext.name           = 'pg_ext'
	ext.gem_spec       = $gem_spec
	ext.ext_dir        = 'ext'
	ext.lib_dir        = 'lib'
	ext.source_pattern = "*.{c,h}"
	ext.cross_compile  = true

	# Activate current cross compiled platform only.
	# This is to work around the issue that `linux` platform is selected in `linux-musl` image.
	ext.cross_platform = CrossLibraries.map(&:platform).select do |pl|
		m = ENV["RCD_IMAGE"]&.match(/:(?<ruby_ver>[\w\.]+)-mri-(?<platform>[-\w]+)$/)
		m && m[:platform] == pl
	end

	ext.cross_config_options += CrossLibraries.map do |xlib|
		{
			xlib.platform => [
				"--with-cross-build=#{xlib.platform}",
				"--with-openssl-platform=#{xlib.openssl_config}",
				"--with-toolchain=#{xlib.toolchain}",
			]
		}
	end

	# Add libpq.dll/.so to fat binary gemspecs
	ext.cross_compiling do |spec|
		spec.files << "ports/#{spec.platform.to_s}/lib/libpq-ruby-pg.so.1" if spec.platform.to_s =~ /linux/
		spec.files << "ports/#{spec.platform.to_s}/lib/libpq-ruby-pg.1.dylib" if spec.platform.to_s =~ /darwin/
		spec.files << "ports/#{spec.platform.to_s}/lib/libpq.dll" if spec.platform.to_s =~ /mingw|mswin/

		# Binary gems don't need postgresql header+lib files
		spec.metadata.delete("msys2_mingw_dependencies")
	end
end

task 'gem:native:prepare' do
	require 'io/console'
	require 'rake_compiler_dock'

	# Copy gem signing key and certs to be accessible from the docker container
	mkdir_p 'build/gem'
	sh "cp ~/.gem/gem-*.pem build/gem/ || true"
	sh "bundle config set cache_all false"
	sh "bundle package"
	begin
		OpenSSL::PKey.read(File.read(File.expand_path("~/.gem/gem-private_key.pem")), ENV["GEM_PRIVATE_KEY_PASSPHRASE"] || "")
	rescue OpenSSL::PKey::PKeyError
		ENV["GEM_PRIVATE_KEY_PASSPHRASE"] = STDIN.getpass("Enter passphrase of gem signature key: ")
		retry
	end
end

CrossLibraries.each do |xlib|
	platform = xlib.platform
	desc "Build fat binary gem for platform #{platform}"
	task "gem:native:#{platform}" => ['gem:native:prepare'] do
		RakeCompilerDock.sh <<-EOT, platform: platform
			#{ "sudo apt-get update && sudo apt-get install -y bison flex &&" if platform =~ /darwin/ }
			#{ # remove nm on Linux to suppress PostgreSQL's check for exit which raises thread_exit as a false positive:
				"sudo mv `which nm` `which nm`.bak &&" if platform =~ /linux/ }
			sudo apt-get update && sudo apt-get install -y bison flex &&
			(cp build/gem/gem-*.pem ~/.gem/ || true) &&
			bundle install --local &&
			rake native:#{platform} pkg/#{$gem_spec.full_name}-#{platform}.gem MAKEFLAGS="-j`nproc` V=1" RUBY_CC_VERSION=#{RakeCompilerDock.ruby_cc_version("~>4.0", "~>3.0")}
		EOT
	end
	desc "Build the native binary gems"
	multitask 'gem:native' => "gem:native:#{platform}"
end

RSpec::Core::RakeTask.new(:spec).rspec_opts = "--profile -cfdoc"
task :test => :spec

# Use the fivefish formatter for docs generated from development checkout
require 'rdoc/task'

RDoc::Task.new( 'docs' ) do |rdoc|
	rdoc.options = $gem_spec.rdoc_options
	rdoc.rdoc_files = $gem_spec.extra_rdoc_files
	rdoc.generator = :fivefish
	rdoc.rdoc_dir = 'doc'
end

desc "Build the source gem #{$gem_spec.full_name}.gem into the pkg directory"
task :gem => :build

task :clobber do
	puts "Stop any Postmaster instances that remain after testing."
	require_relative 'spec/helpers'
	PG::TestingHelpers.stop_existing_postmasters()
end

desc "Update list of server error codes"
task :update_error_codes do
	# URL_ERRORCODES_TXT = "https://git.postgresql.org/gitweb/?p=postgresql.git;a=blob_plain;f=src/backend/utils/errcodes.txt;hb=refs/tags/REL_18_0"
	URL_ERRORCODES_TXT = "https://raw.githubusercontent.com/postgres/postgres/refs/tags/REL_18_0/src/backend/utils/errcodes.txt"

	ERRORCODES_TXT = "ext/errorcodes.txt"
	sh "wget #{URL_ERRORCODES_TXT.inspect} -O #{ERRORCODES_TXT.inspect} || curl #{URL_ERRORCODES_TXT.inspect} -o #{ERRORCODES_TXT.inspect}"

	ruby 'ext/errorcodes.rb', 'ext/errorcodes.txt', 'ext/errorcodes.def'
end

file 'ext/pg_errors.c' => ['ext/errorcodes.def'] do
	# trigger compilation of changed errorcodes.def
	touch 'ext/pg_errors.c'
end

desc "Translate readme"
task :translate do
  cd "translation" do
    # po4a's lexer might change, so record its version for reference
    sh "LANG=C po4a --version > .po4a-version"

    sh "po4a po4a.cfg"
  end
end
