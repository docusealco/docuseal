# YAML

This module provides a Ruby interface for data serialization in YAML format.

The `YAML` module is an alias for
[Psych](https://ruby-doc.org/stdlib/exts/psych/Psych.html),
the `YAML` engine for Ruby.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'yaml'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install yaml

## Usage

Working with YAML can be very simple, for example:

```ruby
require 'yaml'

# Parse a YAML string
YAML.load("--- foo") #=> "foo"

# Emit some YAML
YAML.dump("foo")     # => "--- foo\n...\n"
{ :a => 'b'}.to_yaml  # => "---\n:a: b\n"
```

For detailed documentation, see
[Psych](https://ruby-doc.org/stdlib/exts/psych/Psych.html).

## Security

Do not use YAML to load untrusted data. Doing so is unsafe and could allow
malicious input to execute arbitrary code inside your application.

## History

Syck was the original for YAML implementation in Ruby's standard library
developed by why the lucky stiff.

You can still use Syck, if you prefer, for parsing and emitting YAML, but you
must install the 'syck' gem now in order to use it.

In older Ruby versions, ie. <= 1.9, Syck is still provided, however it was
completely removed with the release of Ruby 2.0.0.

## More info

For more advanced details on the implementation see Psych, and also check out
http://yaml.org for spec details and other helpful information.

Psych is maintained by Aaron Patterson on github: https://github.com/tenderlove/psych

Syck can also be found on github: https://github.com/tenderlove/syck

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/ruby/yaml.
