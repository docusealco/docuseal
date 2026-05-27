# -*- encoding: utf-8 -*-
# stub: rails-dom-testing 2.3.0 ruby lib

Gem::Specification.new do |s|
  s.name = "rails-dom-testing".freeze
  s.version = "2.3.0".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Rafael Mendon\u00E7a Fran\u00E7a".freeze, "Kasper Timm Hansen".freeze]
  s.date = "1980-01-02"
  s.description = "This gem can compare doms and assert certain elements exists in doms using Nokogiri.".freeze
  s.email = ["rafaelmfranca@gmail.com".freeze, "kaspth@gmail.com".freeze]
  s.homepage = "https://github.com/rails/rails-dom-testing".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.5.0".freeze)
  s.rubygems_version = "3.6.7".freeze
  s.summary = "Dom and Selector assertions for Rails applications".freeze

  s.installed_by_version = "4.0.3".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<activesupport>.freeze, [">= 5.0.0".freeze])
  s.add_runtime_dependency(%q<minitest>.freeze, [">= 0".freeze])
  s.add_runtime_dependency(%q<nokogiri>.freeze, [">= 1.6".freeze])
  s.add_development_dependency(%q<rake>.freeze, [">= 0".freeze])
end
