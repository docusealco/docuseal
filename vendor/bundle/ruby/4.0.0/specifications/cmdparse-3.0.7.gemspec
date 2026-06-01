# -*- encoding: utf-8 -*-
# stub: cmdparse 3.0.7 ruby lib

Gem::Specification.new do |s|
  s.name = "cmdparse".freeze
  s.version = "3.0.7".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Thomas Leitner".freeze]
  s.date = "2020-12-08"
  s.description = "       cmdparse provides classes for parsing (possibly nested) commands on the command line;\n       command line options themselves are parsed using optparse.\n".freeze
  s.email = "t_leitner@gmx.at".freeze
  s.homepage = "https://cmdparse.gettalong.org".freeze
  s.licenses = ["MIT".freeze]
  s.rdoc_options = ["--line-numbers".freeze, "--main".freeze, "CmdParse::CommandParser".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.0.0".freeze)
  s.rubygems_version = "3.0.3".freeze
  s.summary = "Advanced command line parser supporting commands".freeze

  s.installed_by_version = "4.0.3".freeze

  s.specification_version = 4

  s.add_development_dependency(%q<webgen>.freeze, ["~> 1.4".freeze])
end
