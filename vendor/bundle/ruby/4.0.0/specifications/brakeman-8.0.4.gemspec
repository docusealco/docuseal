# -*- encoding: utf-8 -*-
# stub: brakeman 8.0.4 ruby lib

Gem::Specification.new do |s|
  s.name = "brakeman".freeze
  s.version = "8.0.4".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://github.com/presidentbeef/brakeman/issues", "changelog_uri" => "https://github.com/presidentbeef/brakeman/releases", "documentation_uri" => "https://brakemanscanner.org/docs/", "homepage_uri" => "https://brakemanscanner.org/", "source_code_uri" => "https://github.com/presidentbeef/brakeman", "wiki_uri" => "https://github.com/presidentbeef/brakeman/wiki" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Justin Collins".freeze]
  s.date = "2026-02-27"
  s.description = "Brakeman detects security vulnerabilities in Ruby on Rails applications via static analysis.".freeze
  s.email = "gem@brakeman.org".freeze
  s.executables = ["brakeman".freeze]
  s.files = ["bin/brakeman".freeze]
  s.homepage = "https://brakemanscanner.org".freeze
  s.licenses = ["Brakeman Public Use License".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 3.2.0".freeze)
  s.rubygems_version = "3.4.19".freeze
  s.summary = "Security vulnerability scanner for Ruby on Rails.".freeze

  s.installed_by_version = "4.0.3".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<racc>.freeze, [">= 0".freeze])
end
