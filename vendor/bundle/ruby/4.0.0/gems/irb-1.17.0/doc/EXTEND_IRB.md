# Extend IRB

From v1.13.0, IRB provides official APIs to extend its functionality. This feature allows libraries to
customize and enhance their users' IRB sessions by adding new commands and helper methods tailored for
the libraries.

## Helper Methods vs. Commands

- Use a helper method if the operation is meant to return a Ruby object that interacts with the application.
  - For example, an `admin_user` helper method that returns `User.where(admin: true).first`, which can then be used like `login_as(admin_user)`.
- Use a command if the operation fits one of the following:
  - A utility operation that performs non-Ruby related tasks, such as IRB's `edit` command.
  - Displays information, like the `show_source` command.
  - If the operation requires non-Ruby syntax arguments, like `ls -g pattern`.

If you don't know what to pick, go with commands first. Commands are generally safer as they can handle a wider variety of inputs and use cases.

## Commands

Commands are designed to complete certain tasks or display information for the user, similar to shell commands.
Therefore, they are designed to accept a variety of inputs, including those that are not valid Ruby code, such
as `my_cmd Foo#bar` or `my_cmd --flag foo`.

### Example

```rb
require "irb/command"

class Greet < IRB::Command::Base
  category "Greeting"
  description "Greets the user"
  help_message <<~HELP
    Greets the user with the given name.

    Usage: greet <name>
  HELP

  # Any input after the command name will be passed as a single string.
  # If nothing is added after the command, an empty string will be passed.
  def execute(arg)
    puts "Hello! #{arg}"
  end
end

IRB::Command.register(:greet, Greet)
```

As long as the above code is loaded before the IRB session is started, such as in a loaded library or a user's `.irbrc` file, `greet` will be accessible to the user.

```txt
irb(main):001> greet
Hello!
=> nil
irb(main):002> greet Stan
Hello! Stan
=> nil
```

And because the `Greet` command introduces a new category, `Greeting`, a new help message category will be created:

```txt
Help
  help           List all available commands. Use `help <command>` to get information about a specific command.

Greeting
  greet          Greets the user

IRB
  context        Displays current configuration.
  ...
```

If the optional `help_message` attribute is specified, `help greet` will also display it:

```txt
irb(main):001> help greet
Greets the user with the given name.

Usage: greet <name>
```

## Helper methods

Helper methods are designed to be used as Ruby methods, such as `my_helper(arg, kwarg: val).foo`.

The main use case of helper methods is to provide shortcuts for users, providing quick and easy access to
frequently used operations or components within the IRB session. For example, a helper method might simplify
the process of fetching and displaying specific configuration settings or data structures that would otherwise
require multiple steps to access.

### Example

```rb
# This only loads the minimum components required to define and register a helper method.
# It does not load the entire IRB, nor does it initialize it.
require "irb/helper_method"

class MyHelper < IRB::HelperMethod::Base
  description "This is a test helper"

  def execute(arg, kwarg:)
    "arg: #{arg}, kwarg: #{kwarg}"
  end
end

IRB::HelperMethod.register(:my_helper, MyHelper)
```

As long as the above code is loaded before the IRB session is started, such as in a loaded library or a user's `.irbrc` file, `my_helper` will be accessible to the user.

```txt
irb(main):001> my_helper("foo", kwarg: "bar").upcase
=> "ARG: FOO, KWARG: BAR"
```

The registered helper methods will also be listed in the help message's `Helper methods` section:

```txt
Helper methods
  conf           Returns the current context.
  my_helper      This is a test helper
```
