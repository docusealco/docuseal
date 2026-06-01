# PrettyPrint

This class implements a pretty printing algorithm. It finds line breaks and
nice indentations for grouped structure.

By default, the class assumes that primitive elements are strings and each
byte in the strings have single column in width. But it can be used for
other situations by giving suitable arguments for some methods:

* newline object and space generation block for PrettyPrint.new
* optional width argument for PrettyPrint#text
* PrettyPrint#breakable

There are several candidate uses:

* text formatting using proportional fonts
* multibyte characters which has columns different to number of bytes

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'prettyprint'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install prettyprint

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/ruby/prettyprint.
