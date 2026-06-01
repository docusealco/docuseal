# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'letter_opener_web/version'

Gem::Specification.new do |gem|
  gem.name                  = 'letter_opener_web'
  gem.version               = LetterOpenerWeb::VERSION
  gem.authors               = ['Fabio Rehm', 'David Muto']
  gem.email                 = ['fgrehm@gmail.com', 'david.muto@gmail.com']
  gem.description           = 'Gives letter_opener an interface for browsing sent emails'
  gem.summary               = gem.description
  gem.homepage              = 'https://github.com/fgrehm/letter_opener_web'
  gem.license               = 'MIT'
  gem.required_ruby_version = '>= 3.1'

  gem.files         = `git ls-files`.split($INPUT_RECORD_SEPARATOR)
  gem.executables   = gem.files.grep(%r{^exe/}).map { |f| File.basename(f) }
  gem.require_paths = ['lib']

  gem.add_dependency 'actionmailer', '>= 6.1'
  gem.add_dependency 'letter_opener', '~> 1.9'
  gem.add_dependency 'railties', '>= 6.1'
  gem.add_dependency 'rexml'

  gem.metadata['rubygems_mfa_required'] = 'true'
end
