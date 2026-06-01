$:.unshift File.join(File.dirname(__FILE__), 'lib')
require 'cldr-plurals/ruby-runtime/version'

Gem::Specification.new do |s|
  s.name     = "cldr-plurals-runtime-rb"
  s.version  = ::CldrPlurals::RUBY_RUNTIME_VERSION
  s.authors  = ["Cameron Dutro"]
  s.email    = ["camertron@gmail.com"]
  s.homepage = "http://github.com/camertron"
  s.license  = "MIT"

  s.description = s.summary = 'Ruby runtime methods for CLDR plural rules (see camertron/cldr-plurals).'
  s.platform = Gem::Platform::RUBY

  s.require_path = 'lib'
  s.files = Dir["{lib,spec}/**/*", "Gemfile", "History.txt", "LICENSE.txt", "README.md", "Rakefile", "cldr-plurals-runtime-rb.gemspec"]
end
