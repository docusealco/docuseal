# -*- encoding: utf-8 -*-
# stub: connection_pool 3.0.2 ruby lib

Gem::Specification.new do |s|
  s.name = "connection_pool".freeze
  s.version = "3.0.2".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://github.com/mperham/connection_pool/issues", "changelog_uri" => "https://github.com/mperham/connection_pool/blob/main/Changes.md", "documentation_uri" => "https://github.com/mperham/connection_pool/wiki", "homepage_uri" => "https://github.com/mperham/connection_pool", "rubygems_mfa_required" => "true", "source_code_uri" => "https://github.com/mperham/connection_pool" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Mike Perham".freeze, "Damian Janowski".freeze]
  s.date = "1980-01-02"
  s.description = "Generic connection pool for Ruby".freeze
  s.email = ["mperham@gmail.com".freeze, "damian@educabilia.com".freeze]
  s.homepage = "https://github.com/mperham/connection_pool".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 3.2.0".freeze)
  s.rubygems_version = "3.6.9".freeze
  s.summary = "Generic connection pool for Ruby".freeze

  s.installed_by_version = "4.0.3".freeze

  s.specification_version = 4

  s.add_development_dependency(%q<bundler>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<maxitest>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rake>.freeze, [">= 0".freeze])
end
