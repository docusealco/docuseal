# Faraday Follow Redirects

[![GitHub Workflow Status](https://img.shields.io/github/actions/workflow/status/tisba/faraday-follow-redirects/ci.yaml)](https://github.com/tisba/faraday-follow-redirects/actions?query=branch%3Amain)
[![Gem](https://img.shields.io/gem/v/faraday-follow_redirects.svg?style=flat-square)](https://rubygems.org/gems/faraday-follow_redirects)
[![License](https://img.shields.io/github/license/tisba/faraday-follow-redirects.svg?style=flat-square)](LICENSE.md)

[Faraday](https://github.com/lostisland/faraday) middleware to follow HTTP redirects transparently.

> [!IMPORTANT]
> This is a Faraday 2.x compatible extraction of the deprecated [`FaradayMiddleware::FollowRedirects` (v1.2.0)](https://github.com/lostisland/faraday_middleware/blob/v1.2.0/lib/faraday_middleware/response/follow_redirects.rb). This gem will also work with Faraday 1.x on a best-effort basis. **Faraday 1.x support is considered deprecated, please update to Faraday 2.x as soon as possible!**
>
> We only support non-EOL versions of Ruby. See [Ruby Maintenance Branches](https://www.ruby-lang.org/en/downloads/branches/) for the list of non-EOL Rubies.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'faraday-follow_redirects'
```

And then execute:

```shell
bundle install
```

Or install it yourself as:

```shell
gem install faraday-follow_redirects
```

## Usage

```ruby
require 'faraday/follow_redirects'

Faraday.new(url: url) do |faraday|
  faraday.response :follow_redirects # use Faraday::FollowRedirects::Middleware
  faraday.adapter Faraday.default_adapter
end
```

## Upgrading from Faraday 1.x

If you still use Faraday 1.x, and have uninstalled the `faraday_middleware` gem, all you have to change is:

```diff
- conn.use FaradayMiddleware::FollowRedirects
+ conn.use Faraday::FollowRedirects::Middleware
```

## Development

After checking out the repo, run `bin/setup` to install dependencies.

Then, run `bin/test` to run the tests.

To install this gem onto your local machine, run `rake build`.

To release a new version, make a commit with a message such as "Bumped to 0.0.2" and then run `rake release`.
See how it works [here](https://bundler.io/guides/creating_gem.html#releasing-the-gem).

The `.ruby-version` file defines the default version to be used for development.

### Appraisal for testing multiple versions of dependencies

We use [appraisal](https://github.com/thoughtbot/appraisal) to test against both faraday 1.x and 2.x, and `./bin/test` will run tests against both. To run tests against just one you could:

```shell
bundle exec appraisal faraday_1 rspec
bundle exec appraisal faraday_2 rspec
```

## Contributing

Bug reports and pull requests are welcome on [GitHub](https://github.com/tisba/faraday-follow-redirects).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
