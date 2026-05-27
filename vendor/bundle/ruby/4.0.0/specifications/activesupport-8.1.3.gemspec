# -*- encoding: utf-8 -*-
# stub: activesupport 8.1.3 ruby lib

Gem::Specification.new do |s|
  s.name = "activesupport".freeze
  s.version = "8.1.3".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://github.com/rails/rails/issues", "changelog_uri" => "https://github.com/rails/rails/blob/v8.1.3/activesupport/CHANGELOG.md", "documentation_uri" => "https://api.rubyonrails.org/v8.1.3/", "mailing_list_uri" => "https://discuss.rubyonrails.org/c/rubyonrails-talk", "rubygems_mfa_required" => "true", "source_code_uri" => "https://github.com/rails/rails/tree/v8.1.3/activesupport" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["David Heinemeier Hansson".freeze]
  s.date = "1980-01-02"
  s.description = "A toolkit of support libraries and Ruby core extensions extracted from the Rails framework. Rich support for multibyte strings, internationalization, time zones, and testing.".freeze
  s.email = "david@loudthinking.com".freeze
  s.homepage = "https://rubyonrails.org".freeze
  s.licenses = ["MIT".freeze]
  s.rdoc_options = ["--encoding".freeze, "UTF-8".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 3.2.0".freeze)
  s.rubygems_version = "4.0.6".freeze
  s.summary = "A toolkit of support libraries and Ruby core extensions extracted from the Rails framework.".freeze

  s.installed_by_version = "4.0.3".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<i18n>.freeze, [">= 1.6".freeze, "< 2".freeze])
  s.add_runtime_dependency(%q<tzinfo>.freeze, ["~> 2.0".freeze, ">= 2.0.5".freeze])
  s.add_runtime_dependency(%q<concurrent-ruby>.freeze, ["~> 1.0".freeze, ">= 1.3.1".freeze])
  s.add_runtime_dependency(%q<connection_pool>.freeze, [">= 2.2.5".freeze])
  s.add_runtime_dependency(%q<minitest>.freeze, [">= 5.1".freeze])
  s.add_runtime_dependency(%q<base64>.freeze, [">= 0".freeze])
  s.add_runtime_dependency(%q<drb>.freeze, [">= 0".freeze])
  s.add_runtime_dependency(%q<bigdecimal>.freeze, [">= 0".freeze])
  s.add_runtime_dependency(%q<json>.freeze, [">= 0".freeze])
  s.add_runtime_dependency(%q<logger>.freeze, [">= 1.4.2".freeze])
  s.add_runtime_dependency(%q<securerandom>.freeze, [">= 0.3".freeze])
  s.add_runtime_dependency(%q<uri>.freeze, [">= 0.13.1".freeze])
end
