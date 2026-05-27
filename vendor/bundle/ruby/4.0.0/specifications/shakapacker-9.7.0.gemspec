# -*- encoding: utf-8 -*-
# stub: shakapacker 9.7.0 ruby lib

Gem::Specification.new do |s|
  s.name = "shakapacker".freeze
  s.version = "9.7.0".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "source_code_uri" => "https://github.com/shakacode/shakapacker/tree/v9.7.0" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["David Heinemeier Hansson".freeze, "Gaurav Tiwari".freeze, "Justin Gordon".freeze]
  s.date = "1980-01-02"
  s.email = ["david@basecamp.com".freeze, "gaurav@gauravtiwari.co.uk".freeze, "justin@shakacode.com".freeze]
  s.homepage = "https://github.com/shakacode/shakapacker".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.7.0".freeze)
  s.rubygems_version = "3.7.2".freeze
  s.summary = "Use webpack to manage app-like JavaScript modules in Rails".freeze

  s.installed_by_version = "4.0.3".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<activesupport>.freeze, [">= 5.2".freeze])
  s.add_runtime_dependency(%q<package_json>.freeze, [">= 0".freeze])
  s.add_runtime_dependency(%q<railties>.freeze, [">= 5.2".freeze])
  s.add_runtime_dependency(%q<rack-proxy>.freeze, [">= 0.6.1".freeze])
  s.add_runtime_dependency(%q<semantic_range>.freeze, [">= 2.3.0".freeze])
  s.add_development_dependency(%q<bundler>.freeze, [">= 1.3.0".freeze])
  s.add_development_dependency(%q<rbs>.freeze, ["~> 3.0".freeze])
  s.add_development_dependency(%q<rubocop>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rubocop-performance>.freeze, [">= 0".freeze])
end
