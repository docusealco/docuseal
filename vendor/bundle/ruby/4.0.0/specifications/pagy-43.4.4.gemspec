# -*- encoding: utf-8 -*-
# stub: pagy 43.4.4 ruby lib

Gem::Specification.new do |s|
  s.name = "pagy".freeze
  s.version = "43.4.4".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://github.com/ddnexus/pagy/issues", "changelog_uri" => "https://ddnexus.github.io/pagy/changelog/", "documentation_uri" => "https://ddnexus.github.io/pagy", "homepage_uri" => "https://github.com/ddnexus/pagy", "rubygems_mfa_required" => "true", "support" => "https://github.com/ddnexus/pagy/discussions/categories/q-a" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Domizio Demichelis".freeze]
  s.date = "1980-01-02"
  s.description = "Agnostic pagination in plain ruby.".freeze
  s.email = ["dd.nexus@gmail.com".freeze]
  s.executables = ["pagy".freeze]
  s.files = ["bin/pagy".freeze]
  s.homepage = "https://github.com/ddnexus/pagy".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 3.2".freeze)
  s.rubygems_version = "4.0.3".freeze
  s.summary = "Pagy \u{1F438} The Leaping Gem!".freeze

  s.installed_by_version = "4.0.3".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<json>.freeze, [">= 0".freeze])
  s.add_runtime_dependency(%q<uri>.freeze, [">= 0".freeze])
  s.add_runtime_dependency(%q<yaml>.freeze, [">= 0".freeze])
end
