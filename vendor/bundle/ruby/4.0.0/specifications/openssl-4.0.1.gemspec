# -*- encoding: utf-8 -*-
# stub: openssl 4.0.1 ruby lib
# stub: ext/openssl/extconf.rb

Gem::Specification.new do |s|
  s.name = "openssl".freeze
  s.version = "4.0.1".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "msys2_mingw_dependencies" => "openssl" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Martin Bosslet".freeze, "SHIBATA Hiroshi".freeze, "Zachary Scott".freeze, "Kazuki Yamaguchi".freeze]
  s.date = "1980-01-02"
  s.description = "OpenSSL for Ruby provides access to SSL/TLS and general-purpose cryptography based on the OpenSSL library.".freeze
  s.email = ["ruby-core@ruby-lang.org".freeze]
  s.extensions = ["ext/openssl/extconf.rb".freeze]
  s.extra_rdoc_files = ["CONTRIBUTING.md".freeze, "History.md".freeze, "README.md".freeze]
  s.files = ["CONTRIBUTING.md".freeze, "History.md".freeze, "README.md".freeze, "ext/openssl/extconf.rb".freeze]
  s.homepage = "https://github.com/ruby/openssl".freeze
  s.licenses = ["Ruby".freeze, "BSD-2-Clause".freeze]
  s.rdoc_options = ["--main".freeze, "README.md".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.7.0".freeze)
  s.rubygems_version = "4.0.3".freeze
  s.summary = "SSL/TLS and general-purpose cryptography for Ruby".freeze

  s.installed_by_version = "4.0.3".freeze
end
