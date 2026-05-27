# -*- encoding: utf-8 -*-
# stub: trilogy 2.12.2 ruby lib
# stub: ext/trilogy-ruby/extconf.rb

Gem::Specification.new do |s|
  s.name = "trilogy".freeze
  s.version = "2.12.2".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["GitHub Engineering".freeze]
  s.date = "1980-01-02"
  s.email = "opensource+trilogy@github.com".freeze
  s.extensions = ["ext/trilogy-ruby/extconf.rb".freeze]
  s.files = ["ext/trilogy-ruby/extconf.rb".freeze]
  s.homepage = "https://github.com/trilogy-libraries/trilogy".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 3.0".freeze)
  s.rubygems_version = "4.0.6".freeze
  s.summary = "A friendly MySQL-compatible library for Ruby, binding to libtrilogy".freeze

  s.installed_by_version = "4.0.3".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<bigdecimal>.freeze, [">= 0".freeze])
end
