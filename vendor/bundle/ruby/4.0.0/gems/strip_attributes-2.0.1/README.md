# StripAttributes

[![Gem Version](http://img.shields.io/gem/v/strip_attributes.svg)](https://rubygems.org/gems/strip_attributes)
[![Build Status](https://github.com/rmm5t/strip_attributes/workflows/CI/badge.svg)](https://github.com/rmm5t/strip_attributes/actions/workflows/ci.yml)
[![Gem Downloads](https://img.shields.io/gem/dt/strip_attributes.svg)](https://rubygems.org/gems/strip_attributes)

StripAttributes is an ActiveModel extension that automatically strips all
attributes of leading and trailing whitespace before validation. If the
attribute is blank, it strips the value to `nil` by default.

It works by adding a before_validation hook to the record.  By default, all
attributes are stripped of whitespace, but `:only` and `:except`
options can be used to limit which attributes are stripped.  Both options accept
a single attribute (`only: :field`) or arrays of attributes (`except: [:field1, :field2, :field3]`).

It's also possible to skip stripping the attributes altogether per model using the `:if` and `:unless` options.

## Installation

Include the gem in your Gemfile:

```ruby
gem "strip_attributes"
```

## Examples

### Default Behavior

```ruby
class DrunkPokerPlayer < ActiveRecord::Base
  strip_attributes
end
```

### Using `except`

```ruby
# all attributes will be stripped except :boxers
class SoberPokerPlayer < ActiveRecord::Base
  strip_attributes except: :boxers
end
```

### Using `only`

```ruby
# only :shoe, :sock, and :glove attributes will be stripped
class ConservativePokerPlayer < ActiveRecord::Base
  strip_attributes only: [:shoe, :sock, :glove]
end
```

### Using `if`

```ruby
# Only records with odd ids will be stripped
class OddPokerPlayer < ActiveRecord::Base
  strip_attributes if: :strip_me?

  def strip_me?
    id.odd?
  end
end
```

### Using `unless`

```ruby
# strip_attributes will be applied randomly
class RandomPokerPlayer < ActiveRecord::Base
  strip_attributes unless: :strip_me?

  def strip_me?
    [true, false].sample
  end
end
```

### Using `allow_empty`

```ruby
# Empty attributes will not be converted to nil
class BrokePokerPlayer < ActiveRecord::Base
  strip_attributes allow_empty: true
end
```

### Using `collapse_spaces`

```ruby
# Sequential spaces in attributes will be collapsed to one space
class EloquentPokerPlayer < ActiveRecord::Base
  strip_attributes collapse_spaces: true
end
```

### Using `replace_newlines`

```ruby
# Newlines in attributes will be replaced with a space
class EloquentPokerPlayer < ActiveRecord::Base
  strip_attributes replace_newlines: true
end
```

### Using `regex`

```ruby
class User < ActiveRecord::Base
  # Strip off characters defined by RegEx
  strip_attributes only: [:first_name, :last_name], regex: /[^[:alpha:]\s]/

  # Strip off non-integers
  strip_attributes only: :phone, regex: /[^0-9]/

  # Strip off all spaces and keep only alphabetic and numeric characters
  strip_attributes only: :nickname, regex: /[^[:alnum:]_-]/

  # Remove trailing whitespace from a multi-line string
  strip_attributes only: :code, regex: /[[:blank:]]+$/)
end
```

## Usage Patterns

### Other ORMs implementing `ActiveModel`

It also works on other ActiveModel classes, such as [Mongoid](http://mongoid.org/) documents:

```ruby
class User
  include Mongoid::Document
  strip_attributes only: :email
end
```

### Using it with [`ActiveAttr`](https://github.com/cgriego/active_attr)

```ruby
class Person
  include ActiveAttr::Model
  include ActiveModel::Validations::Callbacks

  attribute :name
  attribute :email

  strip_attributes
end

```

### Using it directly

```ruby
# where record is an ActiveModel instance
StripAttributes.strip(record, collapse_spaces: true)

# works directly on Strings too
StripAttributes.strip(" foo \t") #=> "foo"
StripAttributes.strip(" foo   bar", collapse_spaces: true) #=> "foo bar"
```

## Testing

StripAttributes provides an RSpec/Shoulda-compatible matcher for easier
testing of attribute assignment. You can use this with
[RSpec](http://rspec.info/), [Shoulda](https://github.com/thoughtbot/shoulda),
[Minitest-MatchersVaccine](https://github.com/rmm5t/minitest-matchers_vaccine)
(preferred), or
[Minitest-Matchers](https://github.com/wojtekmach/minitest-matchers).

### Setup `spec_helper.rb` or `test_helper.rb`

#### To initialize **RSpec**, add this to your `spec_helper.rb`:

```ruby
require "strip_attributes/matchers"
RSpec.configure do |config|
  config.include StripAttributes::Matchers
end
```

#### To initialize **Shoulda (with test-unit)**, add this to your `test_helper.rb`:

```ruby
require "strip_attributes/matchers"
class Test::Unit::TestCase
  extend StripAttributes::Matchers
end
```

OR if in a Rails environment, you might prefer this:

``` ruby
require "strip_attributes/matchers"
class ActiveSupport::TestCase
  extend StripAttributes::Matchers
end
```

#### To initialize **Minitest-MatchersVaccine**, add this to your `test_helper.rb`:

```ruby
require "strip_attributes/matchers"
class MiniTest::Spec
  include StripAttributes::Matchers
end
```

OR if in a Rails environment, you might prefer this:

``` ruby
require "strip_attributes/matchers"
class ActiveSupport::TestCase
  include StripAttributes::Matchers
end
```

#### To initialize **Minitest-Matchers**, add this to your `test_helper.rb`:

```ruby
require "strip_attributes/matchers"
class MiniTest::Spec
  include StripAttributes::Matchers
end
```

### Writing Tests

**RSpec**:

```ruby
describe User do
  it { is_expected.to strip_attribute(:name).collapse_spaces }
  it { is_expected.to strip_attribute(:name).replace_newlines }
  it { is_expected.to strip_attribute :email }
  it { is_expected.to strip_attributes(:name, :email) }
  it { is_expected.to strip_attributes(:ticker).using("AAPL") }
  it { is_expected.not_to strip_attribute :password }
  it { is_expected.not_to strip_attributes(:password, :encrypted_password)  }
end
```

**Shoulda (with test-unit)**:

```ruby
class UserTest < ActiveSupport::TestCase
  should strip_attribute(:name).collapse_spaces
  should strip_attribute(:name).replace_newlines
  should strip_attribute :email
  should strip_attributes(:name, :email)
  should strip_attributes(:ticker).using("AAPL")
  should_not strip_attribute :password
  should_not strip_attributes(:password, :encrypted_password)
end
```

**Minitest-MatchersVaccine**:

```ruby
describe User do
  subject { User.new }

  it "should strip attributes" do
    must strip_attribute(:name).collapse_spaces
    must strip_attribute(:name).replace_newlines
    must strip_attribute :email
    must strip_attributes(:name, :email)
    must strip_attributes(:ticker).using("AAPL")
    wont strip_attribute :password
    wont strip_attributes(:password, :encrypted_password)
  end
end
```

**Minitest-Matchers**:

```ruby
describe User do
  subject { User.new }

  must { strip_attribute(:name).collapse_spaces }
  must { strip_attribute(:name).replace_newlines }
  must { strip_attribute :email }
  must { strip_attributes(:name, :email) }
  must { strip_attributes(:ticker).using("AAPL") }
  wont { strip_attribute :password }
  wont { strip_attributes(:password, :encrypted_password) }
end
```

## Support

Submit suggestions or feature requests as a GitHub Issue or Pull
Request (preferred). If you send a pull request, remember to update the
corresponding unit tests.  In fact, I prefer new features to be submitted in the
form of new unit tests.

## Credits

The idea was originally triggered by the information at the (now defunct)
Rails Wiki but was modified from the original to include more idiomatic ruby
and rails support.

## Versioning

Semantic Versioning 2.0 as defined at <http://semver.org>.

## License

[MIT License](https://rmm5t.mit-license.org/)
