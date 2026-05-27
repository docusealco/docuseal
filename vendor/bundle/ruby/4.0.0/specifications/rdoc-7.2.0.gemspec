# -*- encoding: utf-8 -*-
# stub: rdoc 7.2.0 ruby lib

Gem::Specification.new do |s|
  s.name = "rdoc".freeze
  s.version = "7.2.0".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 2.2".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "changelog_uri" => "https://github.com/ruby/rdoc/releases", "homepage_uri" => "https://ruby.github.io/rdoc", "source_code_uri" => "https://github.com/ruby/rdoc" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Eric Hodel".freeze, "Dave Thomas".freeze, "Phil Hagelberg".freeze, "Tony Strauss".freeze, "Zachary Scott".freeze, "Hiroshi SHIBATA".freeze, "ITOYANAGI Sakura".freeze]
  s.bindir = "exe".freeze
  s.date = "2026-02-09"
  s.description = "RDoc produces HTML and command-line documentation for Ruby projects.\nRDoc includes the +rdoc+ and +ri+ tools for generating and displaying documentation from the command-line.\n".freeze
  s.email = ["drbrain@segment7.net".freeze, "".freeze, "".freeze, "".freeze, "mail@zzak.io".freeze, "hsbt@ruby-lang.org".freeze, "aycabta@gmail.com".freeze]
  s.executables = ["rdoc".freeze, "ri".freeze]
  s.extra_rdoc_files = ["CONTRIBUTING.md".freeze, "CVE-2013-0256.rdoc".freeze, "History.rdoc".freeze, "LEGAL.rdoc".freeze, "LICENSE.rdoc".freeze, "README.md".freeze, "RI.md".freeze, "TODO.rdoc".freeze]
  s.files = ["CONTRIBUTING.md".freeze, "CVE-2013-0256.rdoc".freeze, "History.rdoc".freeze, "LEGAL.rdoc".freeze, "LICENSE.rdoc".freeze, "README.md".freeze, "RI.md".freeze, "TODO.rdoc".freeze, "exe/rdoc".freeze, "exe/ri".freeze]
  s.homepage = "https://ruby.github.io/rdoc".freeze
  s.licenses = ["Ruby".freeze]
  s.rdoc_options = ["--main".freeze, "README.md".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.6.0".freeze)
  s.rubygems_version = "4.0.3".freeze
  s.summary = "RDoc produces HTML and command-line documentation for Ruby projects".freeze

  s.installed_by_version = "4.0.3".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<psych>.freeze, [">= 4.0.0".freeze])
  s.add_runtime_dependency(%q<erb>.freeze, [">= 0".freeze])
  s.add_runtime_dependency(%q<tsort>.freeze, [">= 0".freeze])
end
