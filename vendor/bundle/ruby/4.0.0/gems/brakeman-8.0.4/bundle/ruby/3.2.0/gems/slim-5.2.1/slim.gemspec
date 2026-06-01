require File.dirname(__FILE__) + '/lib/slim/version'
require 'date'

Gem::Specification.new do |s|
  s.name              = 'slim'
  s.version           = Slim::VERSION
  s.date              = Date.today.to_s
  s.authors           = ['Daniel Mendler', 'Andrew Stone', 'Fred Wu']
  s.email             = ['mail@daniel-mendler.de', 'andy@stonean.com', 'ifredwu@gmail.com']
  s.summary           = 'Slim is a template language.'
  s.description       = 'Slim is a template language whose goal is reduce the syntax to the essential parts without becoming cryptic.'
  s.homepage          = 'https://slim-template.github.io/'
  s.license           = 'MIT'

  s.metadata = {
    "bug_tracker_uri"   => "https://github.com/slim-template/slim/issues",
    "changelog_uri"     => "https://github.com/slim-template/slim/blob/main/CHANGES",
    "documentation_uri" => "https://rubydoc.info/gems/slim/frames",
    "homepage_uri"      => "https://slim-template.github.io/",
    "source_code_uri"   => "https://github.com/slim-template/slim",
    "wiki_uri"          => "https://github.com/slim-template/slim/wiki",
    "funding_uri"       => "https://github.com/sponsors/slim-template"
  }

  s.files             = `git ls-files`.split("\n")
  s.executables       = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths     = %w(lib)

  s.required_ruby_version = '>= 2.5.0'

  s.add_runtime_dependency('temple', ['~> 0.10.0'])
  s.add_runtime_dependency('tilt', ['>= 2.1.0'])
end
