# Psych

* https://github.com/ruby/psych
* https://docs.ruby-lang.org/en/master/Psych.html

## Description

Psych is a YAML parser and emitter.  Psych leverages
[libyaml](https://pyyaml.org/wiki/LibYAML) for its YAML parsing and emitting
capabilities.  In addition to wrapping libyaml, Psych also knows how to
serialize and de-serialize most Ruby objects to and from the YAML format.

## Examples

```ruby
# Safely load YAML in to a Ruby object
Psych.safe_load('--- foo') # => 'foo'

# Emit YAML from a Ruby object
Psych.dump("foo")     # => "--- foo\n...\n"
```

## Dependencies

* libyaml

## Installation

Psych has been included with MRI since 1.9.2, and is the default YAML parser
in 1.9.3.

If you want a newer gem release of Psych, you can use RubyGems:

```bash
gem install psych
```

Psych supported the static build with specific version of libyaml sources. You can build psych with libyaml-0.2.5 like this.

```bash
gem install psych -- --with-libyaml-source-dir=/path/to/libyaml-0.2.5
```

In order to use the gem release in your app, and not the stdlib version,
you'll need the following:

```ruby
gem 'psych'
require 'psych'
```

Or if you use Bundler add this to your `Gemfile`:

```ruby
gem 'psych'
```

JRuby ships with a pure Java implementation of Psych.

## Release

We used the trusted publisher and [rubygems/release-gem](https://github.com/rubygems/release-gem) workflow.

We can release the new version with:

```bash
git tag vXXX && git push origin vXXX
```

## License

Copyright 2009 Aaron Patterson, et al.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the 'Software'), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
