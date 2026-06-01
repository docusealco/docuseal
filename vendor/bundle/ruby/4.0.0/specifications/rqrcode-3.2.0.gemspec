# -*- encoding: utf-8 -*-
# stub: rqrcode 3.2.0 ruby lib

Gem::Specification.new do |s|
  s.name = "rqrcode".freeze
  s.version = "3.2.0".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://github.com/whomwah/rqrcode/issues", "changelog_uri" => "https://github.com/whomwah/rqrcode/blob/main/CHANGELOG.md" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Duncan Robertson".freeze]
  s.bindir = "exe".freeze
  s.date = "1980-01-02"
  s.description = "rqrcode is a library for encoding QR Codes. The simple\ninterface allows you to create QR Code data structures\nand then render them in the way you choose.\n".freeze
  s.email = ["duncan@whomwah.com".freeze]
  s.homepage = "https://github.com/whomwah/rqrcode".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 3.2".freeze)
  s.rubygems_version = "4.0.3".freeze
  s.summary = "A library to encode QR Codes".freeze

  s.installed_by_version = "4.0.3".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<chunky_png>.freeze, ["~> 1.0".freeze])
  s.add_runtime_dependency(%q<rqrcode_core>.freeze, ["~> 2.0".freeze])
  s.add_development_dependency(%q<benchmark-ips>.freeze, ["~> 2.0".freeze])
  s.add_development_dependency(%q<bundler>.freeze, ["~> 4.0".freeze])
  s.add_development_dependency(%q<memory_profiler>.freeze, ["~> 1.0".freeze])
  s.add_development_dependency(%q<rake>.freeze, ["~> 13.0".freeze])
  s.add_development_dependency(%q<rspec>.freeze, ["~> 3.5".freeze])
  s.add_development_dependency(%q<stackprof>.freeze, ["~> 0.2".freeze])
  s.add_development_dependency(%q<standard>.freeze, ["~> 1.41".freeze])
end
