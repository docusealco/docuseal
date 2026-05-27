require "./lib/connection_pool/version"

Gem::Specification.new do |s|
  s.name = "connection_pool"
  s.version = ConnectionPool::VERSION
  s.platform = Gem::Platform::RUBY
  s.authors = ["Mike Perham", "Damian Janowski"]
  s.email = ["mperham@gmail.com", "damian@educabilia.com"]
  s.homepage = "https://github.com/mperham/connection_pool"
  s.description = s.summary = "Generic connection pool for Ruby"

  s.files = ["Changes.md", "LICENSE", "README.md", "connection_pool.gemspec",
    "lib/connection_pool.rb",
    "lib/connection_pool/timed_stack.rb",
    "lib/connection_pool/version.rb",
    "lib/connection_pool/fork.rb",
    "lib/connection_pool/wrapper.rb"]
  s.executables = []
  s.require_paths = ["lib"]
  s.license = "MIT"

  s.required_ruby_version = ">= 3.2.0"
  s.add_development_dependency "bundler"
  s.add_development_dependency "maxitest"
  s.add_development_dependency "rake"

  s.metadata = {
    "bug_tracker_uri" => "https://github.com/mperham/connection_pool/issues",
    "documentation_uri" => "https://github.com/mperham/connection_pool/wiki",
    "changelog_uri" => "https://github.com/mperham/connection_pool/blob/main/Changes.md",
    "source_code_uri" => "https://github.com/mperham/connection_pool",
    "homepage_uri" => "https://github.com/mperham/connection_pool",
    "rubygems_mfa_required" => "true"
  }
end
