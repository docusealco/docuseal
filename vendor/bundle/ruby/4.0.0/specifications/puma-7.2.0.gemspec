# -*- encoding: utf-8 -*-
# stub: puma 7.2.0 ruby lib
# stub: ext/puma_http11/extconf.rb

Gem::Specification.new do |s|
  s.name = "puma".freeze
  s.version = "7.2.0".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://github.com/puma/puma/issues", "changelog_uri" => "https://github.com/puma/puma/blob/main/History.md", "homepage_uri" => "https://puma.io", "msys2_mingw_dependencies" => "openssl", "rubygems_mfa_required" => "true", "source_code_uri" => "https://github.com/puma/puma" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Evan Phoenix".freeze]
  s.date = "1980-01-02"
  s.description = "Puma is a simple, fast, multi-threaded, and highly parallel HTTP 1.1 server\nfor Ruby/Rack applications. Puma is intended for use in both development and\nproduction environments. It's great for highly parallel Ruby implementations such as\nJRuby and TruffleRuby as well as as providing process worker support to support CRuby well.\n".freeze
  s.email = ["evan@phx.io".freeze]
  s.executables = ["puma".freeze, "pumactl".freeze]
  s.extensions = ["ext/puma_http11/extconf.rb".freeze]
  s.files = ["bin/puma".freeze, "bin/pumactl".freeze, "ext/puma_http11/extconf.rb".freeze]
  s.homepage = "https://puma.io".freeze
  s.licenses = ["BSD-3-Clause".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 3.0".freeze)
  s.rubygems_version = "4.0.3".freeze
  s.summary = "A Ruby/Rack web server built for parallelism.".freeze

  s.installed_by_version = "4.0.3".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<nio4r>.freeze, ["~> 2.0".freeze])
end
