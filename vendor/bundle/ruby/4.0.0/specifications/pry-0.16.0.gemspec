# -*- encoding: utf-8 -*-
# stub: pry 0.16.0 ruby lib

Gem::Specification.new do |s|
  s.name = "pry".freeze
  s.version = "0.16.0".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://github.com/pry/pry/issues", "changelog_uri" => "https://github.com/pry/pry/blob/master/CHANGELOG.md", "source_code_uri" => "https://github.com/pry/pry" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["John Mair (banisterfiend)".freeze, "Conrad Irwin".freeze, "Ryan Fitzgerald".freeze, "Kyrylo Silin".freeze]
  s.date = "1980-01-02"
  s.description = "Pry is a runtime developer console and IRB alternative with powerful\nintrospection capabilities. Pry aims to be more than an IRB replacement. It is\nan attempt to bring REPL driven programming to the Ruby language.\n".freeze
  s.email = ["jrmair@gmail.com".freeze, "conrad.irwin@gmail.com".freeze, "rwfitzge@gmail.com".freeze, "silin@kyrylo.org".freeze]
  s.executables = ["pry".freeze]
  s.files = ["bin/pry".freeze]
  s.homepage = "http://pry.github.io".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.6".freeze)
  s.rubygems_version = "4.0.3".freeze
  s.summary = "A runtime developer console and IRB alternative with powerful introspection capabilities.".freeze

  s.installed_by_version = "4.0.3".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<coderay>.freeze, ["~> 1.1".freeze])
  s.add_runtime_dependency(%q<method_source>.freeze, ["~> 1.0".freeze])
  s.add_runtime_dependency(%q<reline>.freeze, [">= 0.6.0".freeze])
end
