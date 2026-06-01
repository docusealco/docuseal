# SemanticRange

[node-semver](https://github.com/npm/node-semver) written in Ruby for comparison and inclusion of semantic versions and ranges.

**NOTE: current `master` and releases `>= 3` use keyword arguments instead of positional arguments to pass options.
If you used `SemanticRange.compare(a, b, true)` in SemanticRange 2, in SemanticRange 3 use `SemanticRange.compare(a, b, loose: true)`**



## Installation

Add this line to your application's Gemfile:

```ruby
gem 'semantic_range'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install semantic_range

## Usage

```ruby
SemanticRange.valid?('1.2.3') # true
SemanticRange.valid?('a.b.c') # false
SemanticRange.valid('1.2.3') # '1.2.3'
SemanticRange.valid('a.b.c') # nil
SemanticRange.clean('  =v1.2.3   ') # '1.2.3'
SemanticRange.filter(['0.9.0', '1.3.0', '1.5.0', '2.0.5'], '1.3.0 || <1.0.0 || >2.0.0') # ['0.9.0', '1.3.0', '2.0.5']
SemanticRange.satisfies?('1.2.3', '1.x || >=2.5.0 || 5.0.0 - 7.2.3') # true
SemanticRange.gt?('1.2.3', '9.8.7') # false
SemanticRange.lt?('1.2.3', '9.8.7') # true
```

### Options
All functions support optional keyword arguments that modify default behavior. The options supported are:
* `loose` Be more forgiving about not-quite-valid semver strings. Any resulting output will always be 100% strict compliant. `false` by default.

Some functions support `platform` option:
* `platform` Changes behavior for `'Rubygems'` and `'Packagist'`. `nil` by default. See https://github.com/librariesio/semantic_range/issues/59


## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/librariesio/semantic_range. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](https://www.contributor-covenant.org/) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
