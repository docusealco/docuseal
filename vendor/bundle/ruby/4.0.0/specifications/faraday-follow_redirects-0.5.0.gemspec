# -*- encoding: utf-8 -*-
# stub: faraday-follow_redirects 0.5.0 ruby lib

Gem::Specification.new do |s|
  s.name = "faraday-follow_redirects".freeze
  s.version = "0.5.0".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://github.com/tisba/faraday-follow-redirects/issues", "changelog_uri" => "https://github.com/tisba/faraday-follow-redirects/blob/v0.5.0/CHANGELOG.md", "documentation_uri" => "http://www.rubydoc.info/gems/faraday-follow_redirects/0.5.0", "homepage_uri" => "https://github.com/tisba/faraday-follow-redirects", "rubygems_mfa_required" => "true", "source_code_uri" => "https://github.com/tisba/faraday-follow-redirects" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Sebastian Cohnen".freeze]
  s.date = "1980-01-02"
  s.description = "Faraday 1.x and 2.x compatible extraction of FaradayMiddleware::FollowRedirects.\n".freeze
  s.email = ["tisba@users.noreply.github.com".freeze]
  s.homepage = "https://github.com/tisba/faraday-follow-redirects".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.6".freeze)
  s.rubygems_version = "4.0.3".freeze
  s.summary = "Faraday 1.x and 2.x compatible extraction of FaradayMiddleware::FollowRedirects".freeze

  s.installed_by_version = "4.0.3".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<faraday>.freeze, [">= 1".freeze, "< 3".freeze])
end
