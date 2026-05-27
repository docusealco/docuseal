# encoding: utf-8

source "https://rubygems.org"

git_source(:github) { |repo_name| "https://github.com/#{repo_name}" }

# Specify your gem's dependencies in tgem.gemspec
gemspec

gem "simplecov", group: :test, require: false

group :code_quality do
  gem "flog", require: false
  gem "pronto", require: false, platform: :ruby
  gem "pronto-flay", require: false, platform: :ruby
  gem "path_expander", "1.1.1", require: false # Remove this lock when path_expander > 1.1.2 and flay > 2.13.3 is released.
  # gem "pronto-poper", require: false, platform: :ruby
  gem "pronto-reek", require: false, platform: :ruby
  gem "pronto-rubocop", require: false, platform: :ruby
  gem "base64", require: false
end
