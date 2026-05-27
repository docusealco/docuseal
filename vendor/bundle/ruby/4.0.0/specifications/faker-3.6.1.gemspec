# -*- encoding: utf-8 -*-
# stub: faker 3.6.1 ruby lib

Gem::Specification.new do |s|
  s.name = "faker".freeze
  s.version = "3.6.1".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://github.com/faker-ruby/faker/issues", "changelog_uri" => "https://github.com/faker-ruby/faker/blob/main/CHANGELOG.md", "documentation_uri" => "https://rubydoc.info/github/faker-ruby/faker", "rubygems_mfa_required" => "true", "source_code_uri" => "https://github.com/faker-ruby/faker", "yard.run" => "yri" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Benjamin Curtis".freeze, "Vitor Oliveira".freeze]
  s.date = "1980-01-02"
  s.description = "Faker, a port of Data::Faker from Perl, is used to easily generate fake data: names, addresses, phone numbers, etc.".freeze
  s.email = ["benjamin.curtis@gmail.com".freeze, "vbrazo@gmail.com".freeze]
  s.executables = ["faker".freeze]
  s.files = ["bin/faker".freeze]
  s.homepage = "https://github.com/faker-ruby/faker".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 3.1".freeze)
  s.rubygems_version = "4.0.6".freeze
  s.summary = "Easily generate fake data".freeze

  s.installed_by_version = "4.0.3".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<i18n>.freeze, [">= 1.8.11".freeze, "< 2".freeze])
end
