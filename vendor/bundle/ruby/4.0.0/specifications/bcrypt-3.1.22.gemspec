# -*- encoding: utf-8 -*-
# stub: bcrypt 3.1.22 ruby lib
# stub: ext/mri/extconf.rb

Gem::Specification.new do |s|
  s.name = "bcrypt".freeze
  s.version = "3.1.22".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "changelog_uri" => "https://github.com/bcrypt-ruby/bcrypt-ruby/blob/master/CHANGELOG" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Coda Hale".freeze]
  s.date = "1980-01-02"
  s.description = "    bcrypt() is a sophisticated and secure hash algorithm designed by The OpenBSD project\n    for hashing passwords. The bcrypt Ruby gem provides a simple wrapper for safely handling\n    passwords.\n".freeze
  s.email = "coda.hale@gmail.com".freeze
  s.extensions = ["ext/mri/extconf.rb".freeze]
  s.extra_rdoc_files = ["CHANGELOG".freeze, "COPYING".freeze, "README.md".freeze, "lib/bcrypt.rb".freeze, "lib/bcrypt/engine.rb".freeze, "lib/bcrypt/error.rb".freeze, "lib/bcrypt/password.rb".freeze]
  s.files = ["CHANGELOG".freeze, "COPYING".freeze, "README.md".freeze, "ext/mri/extconf.rb".freeze, "lib/bcrypt.rb".freeze, "lib/bcrypt/engine.rb".freeze, "lib/bcrypt/error.rb".freeze, "lib/bcrypt/password.rb".freeze]
  s.homepage = "https://github.com/bcrypt-ruby/bcrypt-ruby".freeze
  s.licenses = ["MIT".freeze]
  s.rdoc_options = ["--title".freeze, "bcrypt-ruby".freeze, "--line-numbers".freeze, "--inline-source".freeze, "--main".freeze, "README.md".freeze]
  s.rubygems_version = "4.0.6".freeze
  s.summary = "OpenBSD's bcrypt() password hashing algorithm.".freeze

  s.installed_by_version = "4.0.3".freeze

  s.specification_version = 4

  s.add_development_dependency(%q<rake-compiler>.freeze, ["~> 1.2.0".freeze])
  s.add_development_dependency(%q<rspec>.freeze, [">= 3".freeze])
  s.add_development_dependency(%q<rdoc>.freeze, [">= 7.0.3".freeze])
  s.add_development_dependency(%q<benchmark>.freeze, [">= 0.5.0".freeze])
end
