# -*- encoding: utf-8 -*-
# stub: pry-rails 0.3.11 ruby lib

Gem::Specification.new do |s|
  s.name = "pry-rails".freeze
  s.version = "0.3.11".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Robin Wenglewski".freeze]
  s.date = "2024-06-20"
  s.email = ["robin@wenglewski.de".freeze]
  s.homepage = "https://github.com/rweng/pry-rails".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 1.9.1".freeze)
  s.rubygems_version = "3.4.1".freeze
  s.summary = "Use Pry as your rails console".freeze

  s.installed_by_version = "4.0.3".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<pry>.freeze, [">= 0.13.0".freeze])
  s.add_development_dependency(%q<appraisal>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<minitest>.freeze, [">= 0".freeze])
end
