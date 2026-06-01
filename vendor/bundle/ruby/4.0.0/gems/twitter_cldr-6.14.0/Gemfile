source "https://rubygems.org"

gemspec

group :development, :test do
  gem 'rake'
  gem 'ruby-prof' unless RUBY_PLATFORM == 'java'
  gem 'regexp_parser', '~> 0.5'
  gem 'benchmark-ips'
  gem 'rubyzip', '~> 1.0'

  # gemspec allows any version, but most people are probably using 1.x, so
  # let's test and develop against that
  gem 'tzinfo', '< 2'
  gem 'tzinfo-data', '= 1.2024.2'  # try to keep in sync with ICU
end

group :development do
  gem 'nokogiri', "~> 1.0"
  gem 'parallel'

  gem 'ruby-cldr', github: 'camertron/ruby-cldr', branch: 'mapzones' # 'svenfuchs/ruby-cldr'
  gem 'i18n'
  gem 'cldr-plurals', '~> 1.1'
  gem 'net-ftp'
  gem 'rexml'
end

group :test do
  gem 'rspec', '~> 3.0'

  gem 'term-ansicolor', '~> 1.3'
  gem 'coveralls', require: false
  gem 'tins', '~> 1.6', require: false

  gem 'simplecov'
  gem 'launchy'
  gem 'addressable', '~> 2.4'
end
