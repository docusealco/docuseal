# email_typo

[![Tests](https://github.com/fnando/email_typo/workflows/Tests/badge.svg)](https://github.com/fnando/email_typo)
[![Code Climate](https://codeclimate.com/github/fnando/email_typo/badges/gpa.svg)](https://codeclimate.com/github/fnando/email_typo)
[![Gem](https://img.shields.io/gem/v/email_typo.svg)](https://rubygems.org/gems/email_typo)
[![Gem](https://img.shields.io/gem/dt/email_typo.svg)](https://rubygems.org/gems/email_typo)

EmailTypo is a Ruby gem that gives you an easy, tested method that fixes email
typos.

As an example: A user with the email "joe@gmail.com" accidentally enters in
"joe@gmal.cmo", EmailTypo will fix it automatically.

EmailTypo is concerned with incorrectly-entered data (email provider names,
TLDs), not with evaluating whether a particular domain is valid, or whether a
particular email address is legitimate. (That is, it's focused on fixing the
part that comes after the "@" in the email address.) It works really well for
helping you — and your users — when they accidentally type something in wrong.

**NOTE**: This is based on https://github.com/charliepark/fat_fingers, but
without polluting the `String` class and with easier extension support.

## Installation

```bash
gem install email_typo
```

Or add the following line to your project's Gemfile:

```ruby
gem "email_typo"
```

## Usage

To fix any typos, just use `EmailTypo.call(email)`.

```ruby
EmailTypo.call("john.doe@gmail.co")
#=> "john.doe@gmail.com"
```

To add/change the processors, add any object that responds to `#call(email)` to
`EmailTypo.default_processors`. The following example adds a processor for
`.uol.com.br`, a Brazilian email provider:

```ruby
EmailTypo.default_processors << lambda do |email|
  email.gsub(/@uol\.com(\..*?)?/, "@uol.com.br")
end
```

## Maintainer

- [Nando Vieira](https://github.com/fnando)

## Contributors

- https://github.com/fnando/email_typo/contributors

## Contributing

For more details about how to contribute, please read
https://github.com/fnando/email_typo/blob/main/CONTRIBUTING.md.

## License

The gem is available as open source under the terms of the
[MIT License](https://opensource.org/licenses/MIT). A copy of the license can be
found at https://github.com/fnando/email_typo/blob/main/LICENSE.md.

## Code of Conduct

Everyone interacting in the email_typo project's codebases, issue trackers, chat
rooms and mailing lists is expected to follow the
[code of conduct](https://github.com/fnando/email_typo/blob/main/CODE_OF_CONDUCT.md).
