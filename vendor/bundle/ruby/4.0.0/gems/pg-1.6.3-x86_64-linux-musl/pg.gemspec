# frozen_string_literal: true
# -*- encoding: utf-8 -*-

require_relative 'lib/pg/version'

Gem::Specification.new do |spec|
  spec.name          = "pg"
  spec.version       = PG::VERSION
  spec.authors       = ["Michael Granger", "Lars Kanis"]
  spec.email         = ["ged@FaerieMUD.org", "lars@greiz-reinsdorf.de"]

  spec.summary       = "Pg is the Ruby interface to the PostgreSQL RDBMS"
  spec.description   = "Pg is the Ruby interface to the PostgreSQL RDBMS. It works with PostgreSQL 10 and later."
  spec.homepage      = "https://github.com/ged/ruby-pg"
  spec.license       = "BSD-2-Clause"
  spec.required_ruby_version = ">= 2.7"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/ged/ruby-pg"
  spec.metadata["changelog_uri"] = "https://github.com/ged/ruby-pg/blob/master/CHANGELOG.md"
  spec.metadata["documentation_uri"] = "http://deveiate.org/code/pg"
  # https://github.com/oneclick/rubyinstaller2/wiki/For-gem-developers#msys2-library-dependency
  spec.metadata["msys2_mingw_dependencies"] = "postgresql"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject do |f|
      f.match(%r{\A(?:test|spec|features|translation|\.)})
    end
  end
  spec.extensions    = ["ext/extconf.rb"]
  spec.require_paths = ["lib"]
  spec.cert_chain    = ["certs/ged.pem"]
  spec.rdoc_options  = ["--main", "README.md",
                        "--title", "PG: The Ruby PostgreSQL Driver"]
  spec.extra_rdoc_files = `git ls-files -z *.rdoc *.md lib/*.rb lib/*/*.rb lib/*/*/*.rb ext/*.c ext/*.h`.split("\x0")
end
