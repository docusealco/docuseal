# frozen_string_literal: true

require_relative 'lib/twitter_cldr/version'

Gem::Specification.new do |s|
  s.name     = 'twitter_cldr'
  s.version  = ::TwitterCldr::VERSION
  s.authors  = ['Cameron Dutro']
  s.email    = ['cdutro@twitter.com']
  s.homepage = 'https://github.com/twitter/twitter-cldr-rb'
  s.license  = 'Apache-2.0'

  s.description = s.summary = 'Ruby implementation of the ICU (International Components for Unicode) that uses the Common Locale Data Repository to format dates, plurals, and more.'

  s.platform = Gem::Platform::RUBY
  s.summary  = 'Ruby implementation of the ICU (International Components for Unicode) that uses the Common Locale Data Repository to format dates, plurals, and more.'

  # json gem since v2.0 requries Ruby ~> 2.0
  s.add_dependency 'camertron-eprun'
  s.add_dependency 'cldr-plurals-runtime-rb', '~> 1.1'
  s.add_dependency 'json', '~> 1.0' if RUBY_VERSION < '2'
  s.add_dependency 'tzinfo'
  s.add_dependency 'base64'

  s.require_path = 'lib'

  s.metadata = {
    'yard.run' => 'yard',
    'bug_tracker_uri' => "#{s.homepage}/issues",
    'changelog_uri' => "#{s.homepage}/blob/master/CHANGELOG.md",
    'documentation_uri' => "https://www.rubydoc.info/gems/#{s.name}",
    'homepage_uri' => s.homepage,
    'source_code_uri' => s.homepage,
    'rubygems_mfa_required' => 'true'
  }

  gem_files       = Dir['{lib,resources}/**/*', 'Gemfile', 'History.txt', 'LICENSE', 'NOTICE', 'README.md',
                        'Rakefile', 'twitter_cldr.gemspec']
  excluded_files  = %w[]
  versioned_files = `git ls-files`.split("\n")

  s.files = (gem_files - excluded_files) & versioned_files
end
