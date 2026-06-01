# StringIO

![ubuntu](https://github.com/ruby/stringio/workflows/ubuntu/badge.svg?branch=master&event=push)
![macos](https://github.com/ruby/stringio/workflows/macos/badge.svg?branch=master&event=push)
![windows](https://github.com/ruby/stringio/workflows/windows/badge.svg?branch=master&event=push)

Pseudo `IO` class from/to `String`.

This library is based on MoonWolf version written in Ruby.  Thanks a lot.

## Differences to `IO`

* `fileno` raises `NotImplementedError`.
* encoding conversion is not implemented, and ignored silently.
* there is no `#to_io` method because this is not an `IO`.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'stringio'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install stringio

## Development

Run `bundle install` to install dependencies and then `bundle exec rake test` to run the tests.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, author a NEWS.md section, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/ruby/stringio.

## License

The gem is available as open source under the terms of the [2-Clause BSD License](https://opensource.org/licenses/BSD-2-Clause).
