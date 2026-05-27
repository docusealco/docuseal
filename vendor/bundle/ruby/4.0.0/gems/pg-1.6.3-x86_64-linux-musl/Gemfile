# -*- ruby -*-

# No pg gem, since "bundle package" fails on bundler-2.7+, if the extension isn't built
# gemspec

source "https://rubygems.org/"

group :development do
  gem "rdoc", "~> 6.4"
  gem "mini_portile2", "~> 2.1"
end

group :test do
  gem "bundler", ">= 1.16", "< 5.0"
  gem "rake-compiler", "~> 1.0"
  gem "rake-compiler-dock", "~> 1.11.0" #, git: "https://github.com/rake-compiler/rake-compiler-dock"
  gem "rspec", "~> 3.5"
  # "bigdecimal" is a gem on ruby-3.4+ and it's optional for ruby-pg.
  # Specs should succeed without it, but 4 examples are then excluded.
  # With bigdecimal commented out here, corresponding tests are omitted on ruby-3.4+ but are executed on ruby < 3.4.
  # That way we can check both situations in CI.
  # gem "bigdecimal", "~> 3.0"
end
