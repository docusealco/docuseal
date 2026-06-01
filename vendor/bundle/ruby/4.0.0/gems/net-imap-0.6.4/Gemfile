# frozen_string_literal: true

source "https://rubygems.org"

gemspec

# gem "digest"  # not included as a workaround for #576
gem "strscan"
gem "base64"
gem "psych", ">= 5.3.0" # 5.2.5 for Data serialization, 5.3.0 for TruffleRuby

gem "irb"
gem "rake"
gem "rdoc", ">= 7.2.0"
gem "test-unit"
gem "test-unit-ruby-core", git: "https://github.com/ruby/test-unit-ruby-core"

gem "benchmark", require: false
gem "benchmark-driver", require: false
gem "vernier", require: false, platform: :mri

group :test do
  gem "simplecov",        require: false, platforms: %i[mri windows]
  gem "simplecov-html",   require: false, platforms: %i[mri windows]
  gem "simplecov-json",   require: false, platforms: %i[mri windows]
end
