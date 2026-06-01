# -*- encoding: utf-8 -*-
# stub: web-console 4.3.0 ruby lib

Gem::Specification.new do |s|
  s.name = "web-console".freeze
  s.version = "4.3.0".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Hailey Somerville".freeze, "Genadi Samokovarov".freeze, "Guillermo Iguaran".freeze, "Ryan Dao".freeze]
  s.date = "1980-01-02"
  s.email = ["hailey@hailey.lol".freeze, "gsamokovarov@gmail.com".freeze, "guilleiguaran@gmail.com".freeze, "daoduyducduong@gmail.com".freeze]
  s.homepage = "https://github.com/rails/web-console".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 3.2".freeze)
  s.rubygems_version = "4.0.3".freeze
  s.summary = "A debugging tool for your Ruby on Rails applications.".freeze

  s.installed_by_version = "4.0.3".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<railties>.freeze, [">= 8.0.0".freeze])
  s.add_runtime_dependency(%q<actionview>.freeze, [">= 8.0.0".freeze])
  s.add_runtime_dependency(%q<bindex>.freeze, [">= 0.4.0".freeze])
end
