# -*- encoding: utf-8 -*-
# stub: rqrcode_core 2.1.0 ruby lib

Gem::Specification.new do |s|
  s.name = "rqrcode_core".freeze
  s.version = "2.1.0".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://github.com/whomwah/rqrcode_core/issues", "changelog_uri" => "https://github.com/whomwah/rqrcode_core/blob/main/CHANGELOG.md" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Duncan Robertson".freeze]
  s.bindir = "exe".freeze
  s.date = "1980-01-02"
  s.description = "rqrcode_core is a Ruby library for encoding QR Codes. The simple\ninterface (with no runtime dependencies) allows you to create QR Code data structures.\n".freeze
  s.email = ["duncan@whomwah.com".freeze]
  s.homepage = "https://github.com/whomwah/rqrcode_core".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 3.2".freeze)
  s.rubygems_version = "4.0.3".freeze
  s.summary = "A library to encode QR Codes".freeze

  s.installed_by_version = "4.0.3".freeze

  s.specification_version = 4

  s.add_development_dependency(%q<benchmark-ips>.freeze, ["~> 2.0".freeze])
  s.add_development_dependency(%q<bundler>.freeze, ["~> 4.0".freeze])
  s.add_development_dependency(%q<memory_profiler>.freeze, ["~> 1.0".freeze])
  s.add_development_dependency(%q<minitest>.freeze, ["~> 6.0".freeze])
  s.add_development_dependency(%q<rake>.freeze, ["~> 13.3".freeze])
  s.add_development_dependency(%q<stackprof>.freeze, ["~> 0.2".freeze])
  s.add_development_dependency(%q<standard>.freeze, ["~> 1.41".freeze])
end
