# -*- encoding: utf-8 -*-
# stub: sqlite3 2.9.2 x86_64-linux-musl lib

Gem::Specification.new do |s|
  s.name = "sqlite3".freeze
  s.version = "2.9.2".freeze
  s.platform = "x86_64-linux-musl".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 3.3.22".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://github.com/sparklemotion/sqlite3-ruby/issues", "changelog_uri" => "https://github.com/sparklemotion/sqlite3-ruby/blob/master/CHANGELOG.md", "documentation_uri" => "https://sparklemotion.github.io/sqlite3-ruby/", "homepage_uri" => "https://github.com/sparklemotion/sqlite3-ruby", "rubygems_mfa_required" => "true", "source_code_uri" => "https://github.com/sparklemotion/sqlite3-ruby" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Jamis Buck".freeze, "Luis Lavena".freeze, "Aaron Patterson".freeze, "Mike Dalessio".freeze]
  s.date = "1980-01-02"
  s.description = "Ruby library to interface with the SQLite3 database engine (http://www.sqlite.org). Precompiled\nbinaries are available for common platforms for recent versions of Ruby.\n".freeze
  s.extra_rdoc_files = ["CHANGELOG.md".freeze, "README.md".freeze, "ext/sqlite3/aggregator.c".freeze, "ext/sqlite3/backup.c".freeze, "ext/sqlite3/database.c".freeze, "ext/sqlite3/exception.c".freeze, "ext/sqlite3/sqlite3.c".freeze, "ext/sqlite3/statement.c".freeze]
  s.files = ["CHANGELOG.md".freeze, "README.md".freeze, "ext/sqlite3/aggregator.c".freeze, "ext/sqlite3/backup.c".freeze, "ext/sqlite3/database.c".freeze, "ext/sqlite3/exception.c".freeze, "ext/sqlite3/sqlite3.c".freeze, "ext/sqlite3/statement.c".freeze]
  s.homepage = "https://github.com/sparklemotion/sqlite3-ruby".freeze
  s.licenses = ["BSD-3-Clause".freeze]
  s.rdoc_options = ["--main".freeze, "README.md".freeze]
  s.required_ruby_version = Gem::Requirement.new([">= 3.2".freeze, "< 4.1.dev".freeze])
  s.rubygems_version = "4.0.3".freeze
  s.summary = "Ruby library to interface with the SQLite3 database engine (http://www.sqlite.org).".freeze

  s.installed_by_version = "4.0.3".freeze
end
