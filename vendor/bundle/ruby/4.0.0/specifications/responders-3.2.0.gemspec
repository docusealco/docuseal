# -*- encoding: utf-8 -*-
# stub: responders 3.2.0 ruby lib

Gem::Specification.new do |s|
  s.name = "responders".freeze
  s.version = "3.2.0".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://github.com/heartcombo/responders/issues", "changelog_uri" => "https://github.com/heartcombo/responders/blob/main/CHANGELOG.md", "homepage_uri" => "https://github.com/heartcombo/responders", "source_code_uri" => "https://github.com/heartcombo/responders" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Jos\u00E9 Valim".freeze]
  s.date = "1980-01-02"
  s.description = "A set of Rails responders to dry up your application".freeze
  s.email = "heartcombo.oss@gmail.com".freeze
  s.homepage = "https://github.com/heartcombo/responders".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.7.0".freeze)
  s.rubygems_version = "3.6.9".freeze
  s.summary = "A set of Rails responders to dry up your application".freeze

  s.installed_by_version = "4.0.3".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<railties>.freeze, [">= 7.0".freeze])
  s.add_runtime_dependency(%q<actionpack>.freeze, [">= 7.0".freeze])
  s.add_development_dependency(%q<mocha>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rails-controller-testing>.freeze, [">= 0".freeze])
end
