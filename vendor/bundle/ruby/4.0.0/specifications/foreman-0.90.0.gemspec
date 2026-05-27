# -*- encoding: utf-8 -*-
# stub: foreman 0.90.0 ruby lib

Gem::Specification.new do |s|
  s.name = "foreman".freeze
  s.version = "0.90.0".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["David Dollar".freeze]
  s.date = "1980-01-02"
  s.description = "Process manager for applications with multiple components".freeze
  s.email = "ddollar@gmail.com".freeze
  s.executables = ["foreman".freeze]
  s.files = ["bin/foreman".freeze]
  s.homepage = "https://github.com/ddollar/foreman".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.6.9".freeze
  s.summary = "Process manager for applications with multiple components".freeze

  s.installed_by_version = "4.0.3".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<thor>.freeze, ["~> 1.4".freeze])
end
