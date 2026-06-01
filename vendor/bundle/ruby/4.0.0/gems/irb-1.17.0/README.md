# IRB

[![Gem Version](https://badge.fury.io/rb/irb.svg)](https://badge.fury.io/rb/irb)
[![Static Badge](https://img.shields.io/badge/RDoc-flat?style=flat&label=documentation&link=https%3A%2F%2Fruby.github.io%2Firb%2F)](https://ruby.github.io/irb/)
[![build](https://github.com/ruby/irb/actions/workflows/test.yml/badge.svg)](https://github.com/ruby/irb/actions/workflows/test.yml)


IRB stands for "interactive Ruby" and is a tool to interactively execute Ruby expressions read from the standard input.

The `irb` command from your shell will start the interpreter.

## Installation

> [!Note]
>
> IRB is a default gem of Ruby so you shouldn't need to install it separately.
>
> But if you're using Ruby 2.6 or later and want to upgrade/install a specific version of IRB, please follow these steps.

To install it with `bundler`, add this line to your application's Gemfile:

```ruby
gem 'irb'
```

And then execute:

```shell
$ bundle
```

Or install it directly with:

```shell
$ gem install irb
```

## Usage

> [!Note]
>
> We're working hard to match Pry's variety of powerful features in IRB, and you can track our progress or find contribution ideas in [this document](https://ruby.github.io/irb/COMPARED_WITH_PRY_md.html).

### The `irb` Executable

You can start a fresh IRB session by typing `irb` in your terminal.

In the session, you can evaluate Ruby expressions or even prototype a small Ruby script. An input is executed when it is syntactically complete.

```shell
$ irb
irb(main):001> 1 + 2
=> 3
irb(main):002* class Foo
irb(main):003*   def foo
irb(main):004*     puts 1
irb(main):005*   end
irb(main):006> end
=> :foo
irb(main):007> Foo.new.foo
1
=> nil
```

### The `binding.irb` Breakpoint

If you use Ruby 2.5 or later versions, you can also use `binding.irb` in your program as breakpoints.

Once a `binding.irb` is evaluated, a new IRB session will be started with the surrounding context:

```shell
$ ruby test.rb

From: test.rb @ line 2 :

    1: def greet(word)
 => 2:   binding.irb
    3:   puts "Hello #{word}"
    4: end
    5:
    6: greet("World")

irb(main):001:0> word
=> "World"
irb(main):002:0> exit
Hello World
```

### Debugging

You can use IRB as a debugging console with `debug.gem` with these options:

- In `binding.irb`, use the `debug` command to start an `irb:rdbg` session with access to all `debug.gem` commands.
- Use the `RUBY_DEBUG_IRB_CONSOLE=1` environment variable to make `debug.gem` use IRB as the debugging console.

To learn more about debugging with IRB, see [Debugging with IRB](https://ruby.github.io/irb/#label-Debugging+with+IRB).

## Documentation

https://ruby.github.io/irb/ provides a comprehensive guide to IRB's features and usage.

## Configuration

See the [Configuration page](https://ruby.github.io/irb/Configurations_md.html) in the documentation.

## Extending IRB

IRB `v1.13.0` and later versions allows users/libraries to extend its functionality through official APIs.

For more information, please visit the [IRB Extension Guide](https://ruby.github.io/irb/EXTEND_IRB_md.html).

## Contributing

See [CONTRIBUTING.md](./CONTRIBUTING.md) for more information.

## Releasing

```
rake release
gh release create vX.Y.Z --generate-notes
```

## License

The gem is available as open source under the terms of the [2-Clause BSD License](https://opensource.org/licenses/BSD-2-Clause).
