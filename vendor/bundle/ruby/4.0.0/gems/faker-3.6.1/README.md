# Faker [![Gem Version][version-badge]][rubygems] [![Build Status][github-actions-badge]][github-actions] [![Total Downloads][downloads-total]][rubygems] [![Downloads][downloads-badge]][rubygems]

<div align="center">
  <img src="https://user-images.githubusercontent.com/36028424/40263395-4318481e-5b44-11e8-92e5-3dcc1ce169b3.png" width="400"/>
  <p>Generate (almost) realistic fake data for testing, demos, and populating your database during development.</p>
</div>

[version-badge]: https://img.shields.io/gem/v/faker.svg
[rubygems]: https://rubygems.org/gems/faker
[github-actions-badge]: https://img.shields.io/github/actions/workflow/status/faker-ruby/faker/.github/workflows/ruby.yml?branch=main
[github-actions]: https://github.com/faker-ruby/faker/actions
[downloads-total]: https://img.shields.io/gem/dt/faker.svg
[downloads-badge]: https://img.shields.io/gem/dtv/faker.svg

## Quick links

- 📖 **[Read the documentation for the latest version][rubydocs].**
- 📢 **[See what's changed in recent versions][changelog].**

[rubydocs]: https://www.rubydoc.info/gems/faker/
[changelog]: CHANGELOG.md

## Features

- Internet: Email addresses, Passwords, Domains, etc.
- Date and Time: Travel back in time or to the future.
- Person: Names, Genders, Bios, Job titles, and more.
- Number and String: Random numbers and strings.
- Location: Addresses, Zip Codes, Street Names, States, and Countries.
- Finance: Account Details, Transactions, and Crypto Addresses.
- Localization - Customize faker with over 40 locales to generate realistic-looking Names, Addresses, and Phone Numbers.

> **Note:** The generated names, addresses, emails, phone numbers, and/or other data might return valid information. Please be careful when using faker in your tests.

For a complete list of the generators, see [Generators](./GENERATORS.md).

## Getting Started

Start by including `faker` in your Gemfile:

```ruby
gem 'faker'
```

Then run `bundle install`.

## Usage

```ruby
require 'faker'

Faker::Name.name                      #=> "Christophe Bartell"
Faker::Internet.password              #=> "Vg5mSvY1UeRg7"
Faker::Internet.email                 #=> "eliza@mann.test"
Faker::Address.full_address           #=> "5479 William Way, East Sonnyhaven, LA 63637"
Faker::Markdown.emphasis              #=> "Quo qui aperiam. Amet corrupti distinctio. Sit quia *dolor.*"
Faker::Lorem.paragraph                #=> "Recusandae minima consequatur. Expedita sequi blanditiis. Ut fuga et."
Faker::Alphanumeric.alpha(number: 10) #=> "zlvubkrwga"
Faker::ProgrammingLanguage.name       #=> "Ruby"
```

## Table of Contents

- [Faker    ](#faker----)
  - [Quick links](#quick-links)
  - [Features](#features)
  - [Getting Started](#getting-started)
  - [Usage](#usage)
  - [Table of Contents](#table-of-contents)
    - [Notes](#notes)
    - [Ensuring unique values](#ensuring-unique-values)
    - [Deterministic Random](#deterministic-random)
    - [Localization](#localization)
    - [Minitest and Faker \>= 2.22](#minitest-and-faker--222)
  - [Generators](#generators)
  - [Contributing](#contributing)
  - [Versioning](#versioning)
  - [Inspiration](#inspiration)
  - [In the media](#in-the-media)
  - [License](#license)

### Notes

* While Faker generates data at random, returned values are not guaranteed to be unique by default. To explicitly specify when you require unique values, see [Ensuring Unique Values](#ensuring-unique-values).
* Values also can be deterministic if you use the deterministic feature, see [Deterministic Random](#deterministic-random).
* This is the `main` branch of Faker and may contain changes that are not yet released. The list of all versions is [available here](https://github.com/stympy/faker/releases).

### Ensuring unique values

To ensure Faker generates unique values, prefix your method call with `unique`:

```ruby
Faker::Name.unique.name # This will return a unique name every time it is called
```

If too many unique values are requested from a generator that has a limited
number of potential values, a `Faker::UniqueGenerator::RetryLimitExceeded`
exception may be raised. It is possible to clear the record of unique values
that have been returned, for example between tests.

```ruby
Faker::Name.unique.clear     # Clears used values for Faker::Name
Faker::UniqueGenerator.clear # Clears used values for all generators
```

You can also give some already-used values to the unique generator if you have
collisions with the generated data (i.e., using FactoryBot with random and
manually set values).

```ruby
# Faker::<generator>.unique.exclude(method, arguments, list)

# Add 'azerty' and 'wxcvbn' to the string generator with 6 char length
Faker::Lorem.unique.exclude :string, [number: 6], %w[azerty wxcvbn]
```

### Deterministic Random

Faker supports seeding of its pseudo-random number generator (PRNG)
to provide deterministic output of repeated method calls.

```ruby
Faker::Config.random = Random.new(42)
Faker::Lorem.word              #=> "velit"
Faker::Lorem.word              #=> "quisquam"

Faker::Config.random = Random.new(42)
Faker::Lorem.word              #=> "velit"
Faker::Lorem.word              #=> "quisquam"

Faker::Config.random = nil     # seeds the PRNG using default entropy sources
Faker::Config.random.seed      #=> 185180369676275068918401850258677722187
Faker::Lorem.word              #=> "ipsam"
```

### Localization

You may want Faker to print information depending on your location in the world.
To assist you in this, Faker uses the `I18n` gem to store strings and formats to
represent the names and postal codes of the area of your choosing.

Just set the locale you want as shown below, and Faker will take care of the rest.

```ruby
Faker::Config.locale = 'es'
# or
Faker::Config.locale = :es
```

To override Faker's locales, and set it on threaded server environments
check out the [locales README](lib/locales/README.md).

### Minitest and Faker >= 2.22

To prevent Faker (version >= 2.22) from [generating duplicate values](https://github.com/faker-ruby/faker/issues/2534) when using Minitest,
you might need to add the following to the `test_helper.rb` or `rails_helper.rb` file:

```ruby
Faker::Config.random = Random.new
```

## Generators

To see the full list, check out the [GENERATORS](./GENERATORS.md) document.

## Contributing

**Note**: We are not accepting proposals for new generators and locales. The [Contributing](https://github.com/faker-ruby/faker/blob/main/CONTRIBUTING.md) guide has a few notes about this decision.

Take a look at the [Contributing](https://github.com/faker-ruby/faker/blob/main/CONTRIBUTING.md) document for
instructions on setting up the repo on your machine, opening bug reports, understanding the codebase,
and creating a good pull request.

There is a [Discord channel](https://discord.gg/RMumTwB) to discuss anything
regarding improvements or feature requests. This is not actively monitored by the current maintainers.

Thank you, contributors!

## Versioning

Faker follows Semantic Versioning 2.0 as defined at https://semver.org.

## Inspiration

Faker was inspired by [Perl's Data::Faker library](https://metacpan.org/pod/Data::Faker).

## In the media

- 📰 [With Great Humor Comes Great Developer Engagement] - KTH Royal Institute of Technology research
- 🎧 [Computer und Kommunikation 4.5.2024, komplette Sendung] - Deutschland Funk Radio Interview

[With Great Humor Comes Great Developer Engagement]: https://arxiv.org/pdf/2312.01680
[Computer und Kommunikation 4.5.2024, komplette Sendung]: https://www.deutschlandfunk.de/computer-und-kommunikation-4-5-2024-komplette-sendung-dlf-16492b03-100.html

## License

This code is free to use under the terms of the MIT license.
