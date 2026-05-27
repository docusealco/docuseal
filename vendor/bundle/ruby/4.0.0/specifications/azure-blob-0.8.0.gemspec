# -*- encoding: utf-8 -*-
# stub: azure-blob 0.8.0 ruby lib

Gem::Specification.new do |s|
  s.name = "azure-blob".freeze
  s.version = "0.8.0".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "changelog_uri" => "https://github.com/testdouble/azure-blob/blob/main/CHANGELOG.md", "homepage_uri" => "https://github.com/testdouble/azure-blob", "rubygems_mfa_required" => "true", "source_code_uri" => "https://github.com/testdouble/azure-blob" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Jo\u00E9 Dupuis".freeze]
  s.bindir = "exe".freeze
  s.date = "1980-01-01"
  s.email = ["joe@dupuis.io".freeze]
  s.homepage = "https://github.com/testdouble/azure-blob".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 3.1".freeze)
  s.rubygems_version = "3.4.19".freeze
  s.summary = "Azure Blob client and Active Storage adapter".freeze

  s.installed_by_version = "4.0.3".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<cgi>.freeze, [">= 0".freeze])
  s.add_runtime_dependency(%q<rexml>.freeze, [">= 0".freeze])
end
