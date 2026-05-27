source "https://rubygems.org"

gemspec

is_unix = RUBY_PLATFORM =~ /(aix|darwin|linux|(net|free|open)bsd|cygwin|solaris|irix|hpux)/i
is_truffleruby = RUBY_DESCRIPTION =~ /truffleruby/

if is_unix && ENV['WITH_VTERM']
  gem "vterm", github: "ruby/vterm-gem"
  gem "yamatanooroti", github: "ruby/yamatanooroti"
end

gem "stackprof" if is_unix && !is_truffleruby

gem "reline", github: "ruby/reline" if ENV["WITH_LATEST_RELINE"] == "true"
gem "rake"
gem "test-unit"
gem "test-unit-ruby-core"

gem "rubocop"

gem "tracer" if !is_truffleruby
gem "debug", github: "ruby/debug"

gem "rdoc", ">= 6.11.0"

if ENV['PRISM_VERSION'] == 'latest'
  gem "prism", github: "ruby/prism"
elsif ENV['PRISM_VERSION']
  gem "prism", ENV['PRISM_VERSION']
else
  gem "prism", "!= 1.8.0"
end

if RUBY_VERSION >= "3.0.0" && !is_truffleruby
  gem "repl_type_completor"
end
