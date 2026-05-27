# -*- encoding: utf-8 -*-
# stub: email_typo 0.2.3 ruby lib

Gem::Specification.new do |s|
  s.name = "email_typo".freeze
  s.version = "0.2.3".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://github.com/fnando/email_typo/issues", "changelog_uri" => "https://github.com/fnando/email_typo/tree/v0.2.3/CHANGELOG.md", "documentation_uri" => "https://github.com/fnando/email_typo/tree/v0.2.3/README.md", "homepage_uri" => "https://github.com/fnando/email_typo", "license_uri" => "https://github.com/fnando/email_typo/tree/v0.2.3/LICENSE.md", "source_code_uri" => "https://github.com/fnando/email_typo/tree/v0.2.3" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Nando Vieira".freeze]
  s.bindir = "exe".freeze
  s.date = "2020-11-09"
  s.description = "Suggest fixes to a misspelled email address, like john@gmail.cmo.".freeze
  s.email = ["me@fnando.com".freeze]
  s.homepage = "https://github.com/fnando/email_typo".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.6.0".freeze)
  s.rubygems_version = "3.1.4".freeze
  s.summary = "Suggest fixes to a misspelled email address, like john@gmail.cmo.".freeze

  s.installed_by_version = "4.0.3".freeze

  s.specification_version = 4

  s.add_development_dependency(%q<email_data>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<minitest>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<minitest-utils>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<pry-meta>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rake>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rubocop>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rubocop-fnando>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<simplecov>.freeze, [">= 0".freeze])
end
