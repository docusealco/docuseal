# parser translation

Prism ships with the ability to translate its syntax tree into the syntax tree used by the [whitequark/parser](https://github.com/whitequark/parser) gem. This allows you to use tools built on top of the `parser` gem with the `prism` parser.

## Usage

The `parser` gem provides multiple parsers to support different versions of the Ruby grammar. This includes all of the Ruby versions going back to 1.8, as well as third-party parsers like MacRuby and RubyMotion. The `prism` gem provides another parser that uses the `prism` parser to build the syntax tree.

You can use the `prism` parser like you would any other. After requiring `prism`, you should be able to call any of the regular `Parser::Base` APIs that you would normally use.

```ruby
require "prism"

# Same as `Parser::Ruby34`
Prism::Translation::Parser34.parse_file("path/to/file.rb")

# Same as `Parser::CurrentRuby`
Prism::Translation::ParserCurrent.parse("puts 'Hello World!'")
```

All the parsers are autoloaded, so you don't have to worry about requiring them yourself.

If you also need to parse Ruby versions below 3.3 (for which the `prism` translation layer does not have explicit support), check out
[this guide](https://github.com/whitequark/parser/blob/master/doc/PRISM_TRANSLATION.md) from the `parser` gem on how to use both in conjunction.
