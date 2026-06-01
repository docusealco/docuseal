# OpenSSL for Ruby

[![Actions Status](https://github.com/ruby/openssl/workflows/CI/badge.svg)](https://github.com/ruby/openssl/actions?workflow=CI)

**OpenSSL for Ruby** provides access to SSL/TLS and general-purpose
cryptography based on the OpenSSL library.

OpenSSL for Ruby is sometimes referred to as **openssl** in all lowercase
or **Ruby/OpenSSL** for disambiguation.

## Compatibility and maintenance policy

OpenSSL for Ruby is released as a RubyGems gem. At the same time, it is part of
the standard library of Ruby. This is called a [default gem].

Each stable branch of OpenSSL for Ruby will remain supported as long as it is
included as a default gem in [supported Ruby branches][Ruby Maintenance Branches].

|Version|Minimum Ruby|OpenSSL compatibility                    |Bundled with|Maintenance  |
|-------|------------|-----------------------------------------|------------|-------------|
|4.0.x  |Ruby 2.7    |OpenSSL 1.1.1-3.x, LibreSSL 3.9+, AWS-LC |Ruby 4.0    |bug fixes    |
|3.3.x  |Ruby 2.7    |OpenSSL 1.0.2-3.x, LibreSSL 3.1+         |Ruby 3.4    |bug fixes    |
|3.2.x  |Ruby 2.7    |OpenSSL 1.0.2-3.x, LibreSSL 3.1+         |Ruby 3.3    |bug fixes    |
|3.1.x  |Ruby 2.6    |OpenSSL 1.0.2-3.x, LibreSSL 3.1+         |Ruby 3.2    |security only|
|3.0.x  |Ruby 2.6    |OpenSSL 1.0.2-3.x, LibreSSL 3.1+         |Ruby 3.1    |end-of-life  |
|2.2.x  |Ruby 2.3    |OpenSSL 1.0.1-1.1.1, LibreSSL 2.9+       |Ruby 3.0    |end-of-life  |
|2.1.x  |Ruby 2.3    |OpenSSL 1.0.1-1.1.1, LibreSSL 2.5+       |Ruby 2.5-2.7|end-of-life  |
|2.0.x  |Ruby 2.3    |OpenSSL 0.9.8-1.1.1, LibreSSL 2.3+       |Ruby 2.4    |end-of-life  |

[default gem]: https://docs.ruby-lang.org/en/master/standard_library_md.html
[Ruby Maintenance Branches]: https://www.ruby-lang.org/en/downloads/branches/

## Installation

> **Note**
> The openssl gem is included with Ruby by default, but you may wish to upgrade
> it to a newer version available at [rubygems.org][RubyGems.org openssl].

To upgrade it, you can use RubyGems:

```
gem install openssl
```

In some cases, it may be necessary to specify the path to the installation
directory of the OpenSSL library.

```
gem install openssl -- --with-openssl-dir=/opt/openssl
```

Alternatively, you can install the gem with Bundler:

```ruby
# Gemfile
gem 'openssl'
# or specify git master
gem 'openssl', git: 'https://github.com/ruby/openssl'
```

After running `bundle install`, you should have the gem installed in your bundle.

[RubyGems.org openssl]: https://rubygems.org/gems/openssl

## Usage

Once installed, you can require "openssl" in your application.

```ruby
require "openssl"
```

## Documentation

See https://ruby.github.io/openssl/.

## Contributing

Please read our [CONTRIBUTING.md] for instructions.

[CONTRIBUTING.md]: https://github.com/ruby/openssl/tree/master/CONTRIBUTING.md

## Security

Security issues should be reported to ruby-core by following the process
described on ["Security at ruby-lang.org"][Security].

[Security]: https://www.ruby-lang.org/en/security/
