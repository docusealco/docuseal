source 'https://rubygems.org'

gemspec

group :development do
  gem 'benchmark' # necessary on ruby-3.5+
  gem 'bigdecimal' # necessary on ruby-3.3+
  gem 'bundler', '>= 1.16', '< 5.dev'
  gem 'fiddle' # necessary on ruby-4.0+
  gem 'rake', '~> 13.0'
  gem 'rake-compiler', '~> 1.1'
  gem 'rake-compiler-dock', '~> 1.11.0'
  gem 'rspec', '~> 3.0'
end

group :doc do
  gem 'kramdown'
  gem 'yard', '~> 0.9'
end

group :type_check do
  if RUBY_VERSION >= "3.0" && %w[ ruby truffleruby ].include?(RUBY_ENGINE)
    gem 'rbs', '~> 3.0'
    gem 'steep', '~> 1.6'
  end
end
