# frozen_string_literal: true

source "https://rubygems.org"

gemspec

group :test do
  gem "rspec", "~> 3.0"
  gem "simplecov", require: false
end

group :development do
  gem "rubocop"
end

group :development, :test do
  gem "pry"
  gem "rake", "~> 13.0"
end
