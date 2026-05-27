# -*- encoding: utf-8 -*-
# stub: retriable 3.4.1 ruby lib

Gem::Specification.new do |s|
  s.name = "retriable".freeze
  s.version = "3.4.1".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Jack Chu".freeze]
  s.date = "1980-01-02"
  s.description = "Retriable is a simple DSL to retry failed code blocks with randomized exponential backoff. This is especially useful when interacting with external APIs/services or file system calls.".freeze
  s.email = ["jack@jackchu.com".freeze]
  s.homepage = "https://github.com/kamui/retriable".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.3.0".freeze)
  s.rubygems_version = "4.0.3".freeze
  s.summary = "Retriable is a simple DSL to retry failed code blocks with randomized exponential backoff".freeze

  s.installed_by_version = "4.0.3".freeze

  s.specification_version = 4

  s.add_development_dependency(%q<bundler>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rspec>.freeze, ["~> 3".freeze])
  s.add_development_dependency(%q<listen>.freeze, ["~> 3.1".freeze])
end
