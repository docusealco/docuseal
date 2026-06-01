# PublicSuffix for Ruby

`PublicSuffix` is a Ruby domain name parser based on the [Public Suffix List](https://publicsuffix.org/).

[![Build Status](https://github.com/weppos/publicsuffix-ruby/actions/workflows/tests.yml/badge.svg)](https://github.com/weppos/publicsuffix-ruby/actions/workflows/tests.yml)
[![Tidelift dependencies](https://tidelift.com/badges/package/rubygems/public_suffix)](https://tidelift.com/subscription/pkg/rubygems-public-suffix?utm_source=rubygems-public-suffix&utm_medium=referral&utm_campaign=enterprise)


## Links

- [Homepage](https://simonecarletti.com/code/publicsuffix-ruby)
- [Repository](https://github.com/weppos/publicsuffix-ruby)
- [API Documentation](https://rubydoc.info/gems/public_suffix)
- [Introducing the Public Suffix List library for Ruby](https://simonecarletti.com/blog/2010/06/public-suffix-list-library-for-ruby/)


## Requirements

`PublicSuffix` requires **Ruby >= 3.2**. For older versions of Ruby, use a previous release.


## Installation

You can install the gem manually:

```shell
gem install public_suffix
```

Or use Bundler and define it as a dependency in your `Gemfile`:

```ruby
gem 'public_suffix'
```

## Usage

Extract the domain out from a name:

```ruby
PublicSuffix.domain("google.com")
# => "google.com"
PublicSuffix.domain("www.google.com")
# => "google.com"
PublicSuffix.domain("www.google.co.uk")
# => "google.co.uk"
```

Parse a domain without subdomains:

```ruby
domain = PublicSuffix.parse("google.com")
# => #<PublicSuffix::Domain>
domain.tld
# => "com"
domain.sld
# => "google"
domain.trd
# => nil
domain.domain
# => "google.com"
domain.subdomain
# => nil
```

Parse a domain with subdomains:

```ruby
domain = PublicSuffix.parse("www.google.com")
# => #<PublicSuffix::Domain>
domain.tld
# => "com"
domain.sld
# => "google"
domain.trd
# => "www"
domain.domain
# => "google.com"
domain.subdomain
# => "www.google.com"
```

Simple validation example:

```ruby
PublicSuffix.valid?("google.com")
# => true

PublicSuffix.valid?("www.google.com")
# => true

# Explicitly forbidden, it is listed as a private domain
PublicSuffix.valid?("blogspot.com")
# => false

# Unknown/not-listed TLD domains are valid by default
PublicSuffix.valid?("example.tldnotlisted")
# => true
```

Strict validation (without applying the default * rule):

```ruby
PublicSuffix.valid?("example.tldnotlisted", default_rule: nil)
# => false
```


## Fully qualified domain names

This library automatically recognizes Fully Qualified Domain Names. A FQDN is a domain name that ends with a trailing dot.

```ruby
# Parse a standard domain name
PublicSuffix.domain("www.google.com")
# => "google.com"

# Parse a fully qualified domain name
PublicSuffix.domain("www.google.com.")
# => "google.com"
```

## Private domains

This library supports toggling private (non-ICANN) domain handling.

```ruby
# Extract a domain including private domains (by default)
PublicSuffix.domain("something.blogspot.com")
# => "something.blogspot.com"

# Extract a domain excluding private domains
PublicSuffix.domain("something.blogspot.com", ignore_private: true)
# => "blogspot.com"

# It also works for #parse and #valid?
PublicSuffix.parse("something.blogspot.com", ignore_private: true)
PublicSuffix.valid?("something.blogspot.com", ignore_private: true)
```

If you don't care about private domains at all, it's more efficient to exclude them when the list is parsed:

```ruby
# Disable support for private TLDs
PublicSuffix::List.default = PublicSuffix::List.parse(File.read(PublicSuffix::List::DEFAULT_LIST_PATH), private_domains: false)
# => "blogspot.com"
PublicSuffix.domain("something.blogspot.com")
# => "blogspot.com"
```

## Adding custom domains

To manually add a domain to the list:

```ruby
PublicSuffix::List.default << PublicSuffix::Rule.factory('onmicrosoft.com')
```

## What is the public suffix list?

The [Public Suffix List](https://publicsuffix.org) is a cross-vendor initiative to provide an accurate list of domain name suffixes.

The Public Suffix List is an initiative of the Mozilla Project, but is maintained as a community resource. It is available for use in any software, but was originally created to meet the needs of browser manufacturers.

A "public suffix" is one under which Internet users can directly register names. Some examples of public suffixes are ".com", ".co.uk" and "pvt.k12.wy.us". The Public Suffix List is a list of all known public suffixes.


## Why use the public suffix list instead of regular expressions?

Previously, browsers used an algorithm which basically only denied setting wide-ranging cookies for top-level domains with no dots (e.g. com or org). However, this did not work for top-level domains where only third-level registrations are allowed (e.g. co.uk). In these cases, websites could set a cookie for co.uk which will be passed onto every website registered under co.uk.

Clearly, this was a security risk as it allowed websites other than the one setting the cookie to read it, and therefore potentially extract sensitive information.

Since there is no algorithmic method of finding the highest level at which a domain may be registered for a particular top-level domain (the policies differ with each registry), the only method is to create a list of all top-level domains and the level at which domains can be registered. This is the aim of the effective TLD list.

As well as being used to prevent cookies from being set where they shouldn't be, the list can also potentially be used for other applications where the registry controlled and privately controlled parts of a domain name need to be known, for example when grouping by top-level domains.

Source: https://wiki.mozilla.org/Public_Suffix_List

Not convinced yet? Check out [this real world example](https://stackoverflow.com/q/288810/123527).


## Does PublicSuffix make network requests?

No. `PublicSuffix` comes with a bundled list. It does not make any HTTP requests to parse or validate a domain.


## Terminology

- **TLD** (Top-Level Domain): The last segment of a domain name. For example, in `mozilla.org`, the `.org` portion is the TLD.

- **SLD** (Second-Level Domain): A domain directly below a top-level domain. For example, in `https://www.mozilla.org/en-US/`, `mozilla` is the second-level domain of the `.org` TLD.

- **TRD** (Third-Level Domain): Also known as a subdomain, this is the part of the domain before the SLD or root domain. For example, in `https://www.mozilla.org/en-US/`, `www` is the TRD.

- **FQDN** (Fully Qualified Domain Name): A complete domain name that includes the hostname, domain, and top-level domain, ending with a trailing dot. The format is `[hostname].[domain].[tld].` (e.g., `www.mozilla.org.`).


## Documentation and support

### Documentation

Library documentation is auto-generated from the [README](https://github.com/weppos/publicsuffix-ruby/blob/master/README.md) and source code, and is available at https://rubydoc.info/gems/public_suffix.

### Bug reports and contributions

- **Bug Tracker**: https://github.com/weppos/publicsuffix-ruby/issues
- **Code Repository**: https://github.com/weppos/publicsuffix-ruby

Contributions are welcome! Please include tests and/or feature coverage for every patch, and create a topic branch for every separate change you make.

### Enterprise support

[Consider subscribing to Tidelift](https://tidelift.com/subscription/pkg/rubygems-public-suffix?utm_source=rubygems-public-suffix&utm_medium=referral&utm_campaign=readme), which provides enterprise support for this project as part of the Tidelift Subscription. Tidelift subscriptions help fund the project, allowing us to ship releases, bugfixes, and security updates more frequently.


## Security and vulnerability reporting

For full information and details about our security policy, please visit [`SECURITY.md`](SECURITY.md).


## Changelog

See [CHANGELOG.md](CHANGELOG.md) for details.


## License

Copyright (c) 2009-2026 Simone Carletti. [MIT License](LICENSE.txt).

The [Public Suffix List source](https://publicsuffix.org/list/) is subject to the terms of the Mozilla Public License, v. 2.0.
