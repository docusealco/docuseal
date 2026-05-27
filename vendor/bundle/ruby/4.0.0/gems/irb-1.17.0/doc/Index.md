# IRB

[![Gem Version](https://badge.fury.io/rb/irb.svg)](https://badge.fury.io/rb/irb)
[![build](https://github.com/ruby/irb/actions/workflows/test.yml/badge.svg)](https://github.com/ruby/irb/actions/workflows/test.yml)

## Overview

IRB stands for "Interactive Ruby" and is a tool to interactively execute Ruby expressions read from the standard input. The `irb` command from your shell will start the interpreter.

IRB provides a shell-like interface that supports user interaction with the Ruby interpreter. It operates as a *read-eval-print loop* ([REPL](https://en.wikipedia.org/wiki/Read%E2%80%93eval%E2%80%93print_loop)) that:

- **Reads** each character as you type. You can modify the IRB context to change the way input works. See [Input](#label-Input).
- **Evaluates** the code each time it has read a syntactically complete passage.
- **Prints** after evaluating. You can modify the IRB context to change the way output works. See [Output](#label-Output).

## Installation

> **Note**
>
> IRB is a default gem of Ruby, so you shouldn't need to install it separately. However, if you're using Ruby 2.6 or later and want to upgrade/install a specific version of IRB, follow these steps.

To install it with `bundler`, add this line to your application's Gemfile:

```ruby
gem 'irb'
```

Then execute:

```console
$ bundle
```

Or install it directly with:

```console
$ gem install irb
```

## Usage

> **Note**
>
> We're working hard to match Pry's variety of powerful features in IRB. Track our progress or find contribution ideas in [COMPARED_WITH_PRY.md](./COMPARED_WITH_PRY.md).

### Starting IRB

You can start a fresh IRB session by typing `irb` in your terminal. In the session, you can evaluate Ruby expressions or prototype small Ruby scripts. Input is executed when it is syntactically complete.

```console
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

If you use Ruby 2.5 or later versions, you can use `binding.irb` in your program as breakpoints. Once `binding.irb` is evaluated, a new IRB session starts with the surrounding context:

```console
$ ruby test.rb

From: test.rb @ line 2 :

    1: def greet(word)
 => 2:   binding.irb
    3:   puts "Hello #{word}"
    4: end
    5:
    6: greet("World")

irb(main):001> word
=> "World"
irb(main):002> exit
Hello World
```

### Debugging

You can use IRB as a debugging console with `debug.gem` with these options:

- In `binding.irb`, use the `debug` command to start an `irb:rdbg` session with access to all `debug.gem` commands.
- Use the `RUBY_DEBUG_IRB_CONSOLE=1` environment variable to make `debug.gem` use IRB as the debugging console.

To learn more about debugging with IRB, see [Debugging with IRB](#label-Debugging+with+IRB).

## Startup

At startup, IRB:

1. Interprets (as Ruby code) the content of the [configuration file](rdoc-ref:Configurations.md) (if given).
2. Constructs the initial session context from [hash IRB.conf](#label-Hash+IRB.conf) and from default values; the hash content may have been affected by [command-line options](#command-line-options), and by direct assignments in the configuration file.
3. Assigns the context to variable `conf`.
4. Assigns command-line arguments to variable `ARGV`.
5. Prints the prompt.
6. Puts the content of the [initialization script](#label-Initialization+script) onto the IRB shell, just as if it were user-typed commands.

## Command Line

On the command line, all options precede all arguments; the first item that is not recognized as an option is treated as an argument, as are all items that follow.

### Command-Line Options

Many command-line options affect entries in hash `IRB.conf`, which in turn affect the initial configuration of the IRB session.

Details of the options are described in relevant subsections below. A cursory list of IRB command-line options may be seen in the [help message](https://raw.githubusercontent.com/ruby/irb/master/lib/irb/lc/help-message), which is also displayed if you use command-line option `--help`.

If you are interested in a specific option, consult the [index](rdoc-ref:COMMAND_LINE_OPTIONS.md).

### Command-Line Arguments

Command-line arguments are passed to IRB in array `ARGV`:

```console
$ irb --noscript Foo Bar Baz
irb(main):001> ARGV
=> ["Foo", "Bar", "Baz"]
irb(main):002> exit
$
```

Command-line option `--` causes everything that follows to be treated as arguments, even those that look like options:

```console
$ irb --noscript -- --noscript -- Foo Bar Baz
irb(main):001> ARGV
=> ["--noscript", "--", "Foo", "Bar", "Baz"]
irb(main):002> exit
$
```

## Commands

The following commands are available in IRB. Use the `help` command to see the list of available commands.

```txt
Help
  help           List all available commands. Use `help <command>` to get information about a specific command.

IRB
  context        Displays current configuration.
  exit           Exit the current irb session.
  exit!          Exit the current process.
  irb_load       Load a Ruby file.
  irb_require    Require a Ruby file.
  source         Loads a given file in the current session.
  irb_info       Show information about IRB.
  history        Shows the input history. `-g [query]` or `-G [query]` allows you to filter the output.
  disable_irb    Disable binding.irb.

Workspace
  cwws           Show the current workspace.
  chws           Change the current workspace to an object.
  workspaces     Show workspaces.
  pushws         Push an object to the workspace stack.
  popws          Pop a workspace from the workspace stack.
  cd             Move into the given object or leave the current context.

Multi-irb (DEPRECATED)
  irb            Start a child IRB.
  jobs           List of current sessions.
  fg             Switches to the session of the given number.
  kill           Kills the session with the given number.

Debugging
  debug          Start the debugger of debug.gem.
  break          Start the debugger of debug.gem and run its `break` command.
  catch          Start the debugger of debug.gem and run its `catch` command.
  next           Start the debugger of debug.gem and run its `next` command.
  delete         Start the debugger of debug.gem and run its `delete` command.
  step           Start the debugger of debug.gem and run its `step` command.
  continue       Start the debugger of debug.gem and run its `continue` command.
  finish         Start the debugger of debug.gem and run its `finish` command.
  backtrace      Start the debugger of debug.gem and run its `backtrace` command.
  info           Start the debugger of debug.gem and run its `info` command.

Misc
  edit           Open a file or source location.
  measure        `measure` enables the mode to measure processing time. `measure :off` disables it.
  copy           Copy expression output to clipboard

Context
  show_doc       Look up documentation with RI.
  ls             Show methods, constants, and variables.
  show_source    Show the source code of a given method, class/module, or constant.
  whereami       Show the source code around binding.irb again.

Helper methods
  conf           Returns the current IRB context.

Aliases
  $              Alias for `show_source`
  @              Alias for `whereami`
```

## Configure IRB

See [Configurations](rdoc-ref:Configurations.md) for more details.

## Input

This section describes the features that allow you to change the way IRB input works; see also [Output](#output).

### Input Command History

By default, IRB stores a history of up to 1000 input commands in a file named `.irb_history`. The history file will be in the same directory as the [configuration file](#label-Configuration+File) if one is found, or in `~/` otherwise.

A new IRB session creates the history file if it does not exist and appends to the file if it does exist.

You can change the filepath by adding to your configuration file:
`IRB.conf[:HISTORY_FILE] = *filepath*`, where *filepath* is a string filepath.

During the session, method `conf.history_file` returns the filepath, and method `conf.history_file = *new_filepath*` copies the history to the file at *new_filepath*, which becomes the history file for the session.

You can change the number of commands saved by adding to your configuration file: `IRB.conf[:SAVE_HISTORY] = *n*`, where *n* is one of:

- Positive integer: the number of commands to be saved.
- Negative integer: all commands are to be saved.
- Zero or `nil`: no commands are to be saved.

During the session, you can use methods `conf.save_history` or `conf.save_history=` to retrieve or change the count.

### Command Aliases

By default, IRB defines several command aliases:

```console
irb(main):001> conf.command_aliases
=> {:"$"=>:show_source, :"@"=>:whereami}
```

You can change the initial aliases in the configuration file with:

```ruby
IRB.conf[:COMMAND_ALIASES] = {foo: :show_source, bar: :whereami}
```

You can replace the current aliases at any time with configuration method `conf.command_aliases=`; because `conf.command_aliases` is a hash, you can modify it.

### End-of-File

By default, `IRB.conf[:IGNORE_EOF]` is `false`, which means that typing the end-of-file character `Ctrl-D` causes the session to exit.

You can reverse that behavior by adding `IRB.conf[:IGNORE_EOF] = true` to the configuration file.

During the session, method `conf.ignore_eof?` returns the setting, and method `conf.ignore_eof = *boolean*` sets it.

### SIGINT

By default, `IRB.conf[:IGNORE_SIGINT]` is `true`, which means that typing the interrupt character `Ctrl-C` does not cause the session to exit.

You can reverse that behavior by adding `IRB.conf[:IGNORE_SIGINT] = false` to the configuration file.

During the session, method `conf.ignore_sigint?` returns the setting, and method `conf.ignore_sigint = *boolean*` sets it.

### Automatic Completion

By default, IRB enables [automatic completion](https://en.wikipedia.org/wiki/Autocomplete#In_command-line_interpreter):

To cycle through the completion suggestions, use the tab key (and shift-tab to reverse).

You can disable it by either of these:

- Adding `IRB.conf[:USE_AUTOCOMPLETE] = false` to the configuration file.
- Giving command-line option `--noautocomplete` (`--autocomplete` is the default).

Method `conf.use_autocomplete?` returns `true` if automatic completion is enabled, `false` otherwise.

The setting may not be changed during the session.

### Type Based Completion

IRB's default completion `IRB::RegexpCompletor` uses Regexp. IRB offers an experimental completion `IRB::TypeCompletor` that uses type analysis.

#### How to Enable IRB::TypeCompletor

Install [ruby/repl_type_completor](https://github.com/ruby/repl_type_completor/) with:

```console
$ gem install repl_type_completor
```

Or add these lines to your project's Gemfile.

```ruby
gem 'irb'
gem 'repl_type_completor', group: [:development, :test]
```

Now you can use type-based completion by:

- Running IRB with the `--type-completor` option

    ```console
    $ irb --type-completor
    ```

- Or writing this line to IRB's rc-file (e.g., `~/.irbrc`)

    ```ruby
    IRB.conf[:COMPLETOR] = :type # default is :regexp
    ```

- Or setting the environment variable `IRB_COMPLETOR`

    ```ruby
    ENV['IRB_COMPLETOR'] = 'type'
    IRB.start
    ```

To check if it's enabled, type `irb_info` into IRB and see the `Completion` section.

```console
irb(main):001> irb_info
...
# Enabled
Completion: Autocomplete, ReplTypeCompletor: 0.1.0, Prism: 0.18.0, RBS: 3.3.0
# Not enabled
Completion: Autocomplete, RegexpCompletor
...
```

If you have a `sig/` directory or `rbs_collection.lock.yaml` in the current directory, IRB will load it.

#### Advantage over Default IRB::RegexpCompletor

`IRB::TypeCompletor` can autocomplete chained methods, block parameters, and more if type information is available. These are some examples `IRB::RegexpCompletor` cannot complete.

```console
irb(main):001> 'Ruby'.upcase.chars.s # Array methods (sample, select, shift, size)
```

```console
irb(main):001> 10.times.map(&:to_s).each do |s|
irb(main):002>   s.up # String methods (upcase, upcase!, upto)
```

```console
irb(main):001> class User < ApplicationRecord
irb(main):002>   def foo
irb(main):003>     sa # save, save!
```

As a trade-off, completion calculation takes more time than `IRB::RegexpCompletor`.

#### Difference between Steep's Completion

Compared with Steep, `IRB::TypeCompletor` has some differences and limitations.
```ruby
[0, 'a'].sample.
# Steep completes the intersection of Integer methods and String methods
# IRB::TypeCompletor completes both Integer and String methods
```

Some features like type narrowing are not implemented.
```ruby
def f(arg = [0, 'a'].sample)
  if arg.is_a?(String)
    arg. # Completes both Integer and String methods
```

Unlike other static type checkers, `IRB::TypeCompletor` uses runtime information to provide better completion.

```console
irb(main):001> a = [1]
=> [1]
irb(main):002> a.first. # Completes Integer methods
```

### Automatic Indentation

By default, IRB automatically indents lines of code to show structure (e.g., it indents the contents of a block).

The current setting is returned by the configuration method `conf.auto_indent_mode`.

The default initial setting is `true`:

```console
irb(main):001> conf.auto_indent_mode
=> true
irb(main):002* Dir.entries('.').select do |entry|
irb(main):003*   entry.start_with?('R')
irb(main):004> end
=> ["README.md", "Rakefile"]
```

You can change the initial setting in the configuration file with:

```ruby
IRB.conf[:AUTO_INDENT] = false
```

Note that the *current* setting *may not* be changed in the IRB session.

### Input Method

The IRB input method determines how command input is read; by default, the input method for a session is IRB::RelineInputMethod unless the TERM environment variable is 'dumb', in which case the most simplistic input method is used.

You can set the input method by:

- Adding to the configuration file:

    - `IRB.conf[:USE_SINGLELINE] = true` or `IRB.conf[:USE_MULTILINE] = false` sets the input method to IRB::ReadlineInputMethod.
    - `IRB.conf[:USE_SINGLELINE] = false` or `IRB.conf[:USE_MULTILINE] = true` sets the input method to IRB::RelineInputMethod.

- Giving command-line options:

  - `--singleline` or `--nomultiline` sets the input method to IRB::ReadlineInputMethod.
  - `--nosingleline` or `--multiline` sets the input method to IRB::RelineInputMethod.
  - `--nosingleline` together with `--nomultiline` sets the input to IRB::StdioInputMethod.

Method `conf.use_multiline?` and its synonym `conf.use_reline` return:

- `true` if option `--multiline` was given.
- `false` if option `--nomultiline` was given.
- `nil` if neither was given.

Method `conf.use_singleline?` and its synonym `conf.use_readline` return:

- `true` if option `--singleline` was given.
- `false` if option `--nosingleline` was given.
- `nil` if neither was given.

## Output

This section describes the features that allow you to change the way IRB output works; see also [Input](#label-Input).

### Return-Value Printing (Echoing)

By default, IRB prints (echoes) the values returned by all input commands.

You can change the initial behavior and suppress all echoing by:

- Adding to the configuration file: `IRB.conf[:ECHO] = false`. (The default value for this entry is `nil`, which means the same as `true`.)
- Giving command-line option `--noecho`. (The default is `--echo`.)

During the session, you can change the current setting with configuration method `conf.echo=` (set to `true` or `false`).

As stated above, by default IRB prints the values returned by all input commands; but IRB offers special treatment for values returned by assignment statements, which may be:

- Printed with truncation (to fit on a single line of output), which is the default; an ellipsis (`...` is suffixed, to indicate the truncation):

    ```console
    irb(main):001> x = 'abc' * 100
    > "abcabcabcabcabcabcabcabcabcabcabcabcabcabcabcabcabcabcabcabcabcabcabcabcabc..."
    ```

- Printed in full (regardless of the length).
- Suppressed (not printed at all).

You can change the initial behavior by:

- Adding to the configuration file: `IRB.conf[:ECHO_ON_ASSIGNMENT] = false`. (The default value for this entry is `nil`, which means the same as `:truncate`.)
- Giving command-line option `--noecho-on-assignment` or `--echo-on-assignment`. (The default is `--truncate-echo-on-assignment`.)

During the session, you can change the current setting with configuration method `conf.echo_on_assignment=` (set to `true`, `false`, or `:truncate`).

By default, IRB formats returned values by calling method `inspect`.

You can change the initial behavior by:

- Adding to the configuration file: `IRB.conf[:INSPECT_MODE] = false`. (The default value for this entry is `true`.)
- Giving command-line option `--noinspect`. (The default is `--inspect`.)

During the session, you can change the setting using method `conf.inspect_mode=`.

### Multiline Output

By default, IRB prefixes a newline to a multiline response.

You can change the initial default value by adding to the configuration file:

```ruby
IRB.conf[:NEWLINE_BEFORE_MULTILINE_OUTPUT] = false
```

During a session, you can retrieve or set the value using methods `conf.newline_before_multiline_output?` and `conf.newline_before_multiline_output=`.

Examples:

```console
irb(main):001> conf.inspect_mode = false
=> false
irb(main):002> "foo\nbar"
=>
foo
bar
irb(main):003> conf.newline_before_multiline_output = false
=> false
irb(main):004> "foo\nbar"
=> foo
bar
```

### Evaluation History

By default, IRB saves no history of evaluations (returned values), and the related methods `conf.eval_history`, `_`, and `__` are undefined.

You can turn on that history and set the maximum number of evaluations to be stored:

- In the configuration file: add `IRB.conf[:EVAL_HISTORY] = *n*`. (Examples below assume that we've added `IRB.conf[:EVAL_HISTORY] = 5`.)
- In the session (at any time): `conf.eval_history = *n*`.

If `n` is zero, all evaluation history is stored.

Doing either of the above:

- Sets the maximum size of the evaluation history; defines method `conf.eval_history`, which returns the maximum size `n` of the evaluation history:

    ```console
    irb(main):001> conf.eval_history = 5
    => 5
    irb(main):002> conf.eval_history
    => 5
    ```

- Defines variable `_`, which contains the most recent evaluation, or `nil` if none; same as method `conf.last_value`:

    ```console
    irb(main):003> _
    => 5
    irb(main):004> :foo
    => :foo
    irb(main):005> :bar
    => :bar
    irb(main):006> _
    => :bar
    irb(main):007> _
    => :bar
    ```

- Defines variable `__`:

    - `__` unadorned: contains all evaluation history:

    ```console
    irb(main):008> :foo
    => :foo
    irb(main):009> :bar
    => :bar
    irb(main):010> :baz
    => :baz
    irb(main):011> :bat
    => :bat
    irb(main):012> :bam
    => :bam
    irb(main):013> __
    =>
    9 :bar
    10 :baz
    11 :bat
    12 :bam
    13 ...self-history...
    ```

    Note that when the evaluation is multiline, it is displayed differently.

    - `__[m]`:

    - Positive `m`: contains the evaluation for the given line number, or `nil` if that line number is not in the evaluation history:

        ```console
        irb(main):015> __[12]
        => :bam
        irb(main):016> __[1]
        => nil
        ```

    - Negative `m`: contains the `mth`-from-end evaluation, or `nil` if that evaluation is not in the evaluation history:

        ```console
        irb(main):017> __[-3]
        => :bam
        irb(main):018> __[-13]
        => nil
        ```

    - Zero `m`: contains `nil`:

        ```console
        irb(main):019> __[0]
        => nil
        ```

### Initialization Script

By default, the first command-line argument (after any options) is the path to a Ruby initialization script.

IRB reads the initialization script and puts its content onto the IRB shell, just as if it were user-typed commands.

Command-line option `--noscript` causes the first command-line argument to be treated as an ordinary argument (instead of an initialization script); `--script` is the default.

## Debugging with IRB

Starting from version 1.8.0, IRB offers a powerful integration with `debug.gem`, providing a debugging experience similar to `pry-byebug`.

After hitting a `binding.irb` breakpoint, you can activate the debugger with the `debug` command. Alternatively, if the `debug` method is already defined in the current scope, you can call `irb_debug`.

```console
From: test.rb @ line 3 :

    1:
    2: def greet(word)
 => 3:   binding.irb
    4:   puts "Hello #{word}"
    5: end
    6:
    7: greet("World")

irb(main):001> debug
irb:rdbg(main):002>
```

Once activated, the prompt's header changes from `irb` to `irb:rdbg`, enabling you to use any of `debug.gem`'s [commands](https://github.com/ruby/debug#debug-command-on-the-debug-console):

```console
irb:rdbg(main):002> info # use info command to see available variables
%self = main
_ = nil
word = "World"
irb:rdbg(main):003> next # use next command to move to the next line
[1, 7] in test.rb
     1|
     2| def greet(word)
     3|   binding.irb
=>   4|   puts "Hello #{word}"
     5| end
     6|
     7| greet("World")
=>#0    Object#greet(word="World") at test.rb:4
  #1    <main> at test.rb:7
irb:rdbg(main):004>
```

Simultaneously, you maintain access to IRB's commands, such as `show_source`:

```console
irb:rdbg(main):004> show_source greet

From: test.rb:2

def greet(word)
  binding.irb
  puts "Hello #{word}"
end
```

### More about `debug.gem`

`debug.gem` offers many advanced debugging features that simple REPLs can't provide, including:

- Step-debugging
- Frame navigation
- Setting breakpoints with commands
- Thread control
- ...and many more

To learn about these features, refer to `debug.gem`'s [commands list](https://github.com/ruby/debug#debug-command-on-the-debug-console).

In the `irb:rdbg` session, the `help` command also displays all commands from `debug.gem`.

### Advantages Over `debug.gem`'s Console

This integration offers several benefits over `debug.gem`'s native console:

1. Access to handy IRB commands like `show_source` or `show_doc`.
2. Support for multi-line input.
3. Symbol shortcuts such as `@` (`whereami`) and `$` (`show_source`).
4. Autocompletion.
5. Customizable prompt.

However, there are some limitations to be aware of:

1. `binding.irb` doesn't support `pre` and `do` arguments like [binding.break](https://github.com/ruby/debug#bindingbreak-method).
2. As IRB [doesn't currently support remote-connection](https://github.com/ruby/irb/issues/672), it can't be used with `debug.gem`'s remote debugging feature.
3. Access to the previous return value via the underscore `_` is not supported.

## Encodings

Command-line option `-E *ex*[:*in*]` sets initial external (ex) and internal (in) encodings.

Command-line option `-U` sets both to UTF-8.

## Contributing

See [CONTRIBUTING.md](https://github.com/ruby/irb/blob/main/CONTRIBUTING.md) for more information.

## Extending IRB

IRB `v1.13.0` and later versions allow users/libraries to extend its functionality through official APIs.

For more information, visit [EXTEND_IRB.md](rdoc-ref:EXTEND_IRB.md).

## License

The gem is available as open source under the terms of the [2-Clause BSD License](https://opensource.org/licenses/BSD-2-Clause).
