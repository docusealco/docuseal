$:.push File.expand_path("../lib", __FILE__)
require "shakapacker/version"

Gem::Specification.new do |s|
  s.name     = "shakapacker"
  s.version  = Shakapacker::VERSION
  s.authors  = [ "David Heinemeier Hansson", "Gaurav Tiwari", "Justin Gordon" ]
  s.email    = [ "david@basecamp.com", "gaurav@gauravtiwari.co.uk", "justin@shakacode.com" ]
  s.summary  = "Use webpack to manage app-like JavaScript modules in Rails"
  s.homepage = "https://github.com/shakacode/shakapacker"
  s.license  = "MIT"

  npm_version = Shakapacker::VERSION.gsub(".rc", "-rc")
  s.metadata = {
    "source_code_uri" => "https://github.com/shakacode/shakapacker/tree/v#{npm_version}",
  }

  s.required_ruby_version = ">= 2.7.0"

  s.add_dependency "activesupport", ">= 5.2"
  s.add_dependency "package_json"
  s.add_dependency "railties",      ">= 5.2"
  s.add_dependency "rack-proxy",    ">= 0.6.1"
  s.add_dependency "semantic_range", ">= 2.3.0"

  s.add_development_dependency "bundler", ">= 1.3.0"
  s.add_development_dependency "rbs", "~> 3.0"
  s.add_development_dependency "rubocop"
  s.add_development_dependency "rubocop-performance"

  s.files = `git ls-files -z`.split("\x0").reject { |f|
    f.match(%r{^(test|spec|features|tmp|node_modules|packages|coverage|Gemfile.lock|rakelib)($|/)}) ||
      f.end_with?(".gem")
  } + Dir.glob("sig/**/*.rbs")

  s.test_files = `git ls-files -- test/*`.split("\n")
end
