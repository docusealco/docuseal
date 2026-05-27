# -*- encoding: utf-8 -*-
# stub: twitter_cldr 6.14.0 ruby lib

Gem::Specification.new do |s|
  s.name = "twitter_cldr".freeze
  s.version = "6.14.0".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://github.com/twitter/twitter-cldr-rb/issues", "changelog_uri" => "https://github.com/twitter/twitter-cldr-rb/blob/master/CHANGELOG.md", "documentation_uri" => "https://www.rubydoc.info/gems/twitter_cldr", "homepage_uri" => "https://github.com/twitter/twitter-cldr-rb", "rubygems_mfa_required" => "true", "source_code_uri" => "https://github.com/twitter/twitter-cldr-rb", "yard.run" => "yard" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Cameron Dutro".freeze]
  s.date = "2025-02-21"
  s.description = "Ruby implementation of the ICU (International Components for Unicode) that uses the Common Locale Data Repository to format dates, plurals, and more.".freeze
  s.email = ["cdutro@twitter.com".freeze]
  s.homepage = "https://github.com/twitter/twitter-cldr-rb".freeze
  s.licenses = ["Apache-2.0".freeze]
  s.rubygems_version = "3.5.16".freeze
  s.summary = "Ruby implementation of the ICU (International Components for Unicode) that uses the Common Locale Data Repository to format dates, plurals, and more.".freeze

  s.installed_by_version = "4.0.3".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<camertron-eprun>.freeze, [">= 0".freeze])
  s.add_runtime_dependency(%q<cldr-plurals-runtime-rb>.freeze, ["~> 1.1".freeze])
  s.add_runtime_dependency(%q<tzinfo>.freeze, [">= 0".freeze])
  s.add_runtime_dependency(%q<base64>.freeze, [">= 0".freeze])
end
