# -*- encoding: utf-8 -*-
# stub: better_html 2.2.0 ruby lib
# stub: ext/better_html_ext/extconf.rb

Gem::Specification.new do |s|
  s.name = "better_html".freeze
  s.version = "2.2.0".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "allowed_push_host" => "https://rubygems.org", "bug_tracker_uri" => "https://github.com/Shopify/better-html/issues", "changelog_uri" => "https://github.com/Shopify/better-html/releases", "source_code_uri" => "https://github.com/Shopify/better-html/tree/v2.2.0" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Francois Chagnon".freeze]
  s.date = "1980-01-02"
  s.description = "Better HTML for Rails. Provides sane html helpers that make it easier to do the right thing.".freeze
  s.email = ["ruby@shopify.com".freeze]
  s.extensions = ["ext/better_html_ext/extconf.rb".freeze]
  s.files = ["ext/better_html_ext/extconf.rb".freeze]
  s.homepage = "https://github.com/Shopify/better-html".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 3.2.0".freeze)
  s.rubygems_version = "3.7.2".freeze
  s.summary = "Better HTML for Rails.".freeze

  s.installed_by_version = "4.0.3".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<actionview>.freeze, [">= 7.0".freeze])
  s.add_runtime_dependency(%q<activesupport>.freeze, [">= 7.0".freeze])
  s.add_runtime_dependency(%q<ast>.freeze, ["~> 2.0".freeze])
  s.add_runtime_dependency(%q<erubi>.freeze, ["~> 1.4".freeze])
  s.add_runtime_dependency(%q<parser>.freeze, [">= 2.4".freeze])
  s.add_runtime_dependency(%q<smart_properties>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rake>.freeze, ["~> 13".freeze])
end
