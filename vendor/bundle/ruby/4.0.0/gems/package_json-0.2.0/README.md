# PackageJson

[![License](https://img.shields.io/badge/license-mit-green.svg)](LICENSE.md)
[![Gem Version](https://badge.fury.io/rb/package_json.svg)](https://badge.fury.io/rb/package_json)
[![Ruby](https://github.com/shakacode/package_json/actions/workflows/checks.yml/badge.svg)](https://github.com/shakacode/package_json/actions/workflows/checks.yml)

The missing gem for managing `package.json` files, without having to know about
package managers (mostly).

It provides an interface for easily modifying the properties of `package.json`
files, along with a "middle-level" abstraction over JavaScript package mangers
to make it easy to manage dependencies without needing to know the specifics of
the underlying package manager (and potentially without even knowing the manager
itself!).

This is _not_ meant to provide the exact same functionality and behaviour
regardless of what package manager is being used, but rather make it easier to
perform common general tasks that are supported by all package managers like
adding new dependencies, installing existing ones, and running scripts without
having to know the actual command a specific package manager requires for that
action (and other such nuances).

## Installation

Install the gem and add to the application's Gemfile by executing:

    $ bundle add package_json

If bundler is not being used to manage dependencies, install the gem by
executing:

    $ gem install package_json

## Usage

```ruby
# represents $PWD/package.json, creating it if it does not exist
package_json = PackageJson.new

# adds eslint, eslint-plugin-prettier, and prettier as development dependencies
package_json.manager.add(%w[eslint prettier], type: :dev)

# adds the "lint" and "format" scripts, preserving any existing scripts
package_json.merge! do |pj|
  {
    "scripts" => pj.fetch("scripts", {}).merge({
      "lint" => "eslint . --ext js",
      "format" => "prettier --check ."
    })
  }
end

# deletes the "babel" property, if it exists
package_json.delete!("babel")

# runs the "lint" script with the "--fix" argument
package_json.manager.run("lint", ["--fix"])
```

The `PackageJson` class represents a `package.json` on disk within a directory;
because it is expected that the `package.json` might be changed by external
sources such as package managers, `PackageJson` reads and writes to and from the
`package.json` as needed rather than representing it in memory.

If you expect the `package.json` to already exist, you can use `read` instead
which will raise an error instead of implicitly creating the file if it doesn't
exist.

A `PackageJson` also comes with a `manager` that can be used to manage
dependencies and run scripts.

### Specifying a package manager

You can specify which package manager should be used with the
[`packageManager`](https://nodejs.org/api/packages.html#packagemanager) property
in the `package.json`.

> **Note**
>
> Only the name of the package manager is used; the version (if present) is
> _not_ checked, nor is [`corepack`](https://nodejs.org/api/corepack.html) used
> to ensure that the package manager is installed.
>
> The manager will be invoked by its name in the directory of the
> `package.json`, and it is up to the developer to ensure that results in the
> desired package manager actually running.

If the `packageManager` property is not present, then the fallback manager will
be used; this defaults to the value of the `PACKAGE_JSON_FALLBACK_MANAGER`
environment variable or otherwise `npm`. You can also provide a specific
fallback manager:

```ruby
PackageJson.read(fallback_manager: :pnpm)
PackageJson.new(fallback_manager: :yarn_classic)
```

Supported package managers are `:npm`, `:yarn_berry`, `:yarn_classic`, `:pnpm`,
and `:bun`.

If the `package.json` does not exist, then the `packageManager` property will be
included based on this value, but it will _not_ be updated if the file already
exists without the property.

Managers are provided a reference to the `PackageJson` when they're initialized,
are run in the same directory as that `PackageJson`.

### Using the package manager

Each package manager supports a set of common methods which are covered below.
Unless otherwise noted for a particular method, each method:

- Behaves like `system`, returning either `true`, `false`, or `nil` based on if
  the package manager exited with a non-zero error code; each method has a
  bang-equivalent if you wish an exception to be thrown instead
- Does not attempt to capture or intercept the output; using `Kernel.system`
  under the hood, output is sent directly to `stdout` and `stderr`
- Will run in the directory of the `package.json`; for methods that generate
  native commands, it is up to the caller to ensure the working directory is
  correct

#### Get the version of the package manager

```ruby
package_json.manager.version
```

This is suitable for checking that the package manager is actually available
before performing other operations. Unlike other non-bang methods, this will
error if the underlying command exits with a non-zero code.

#### Installing dependencies

```ruby
# install all dependencies
package_json.manager.install

# install all dependencies, erroring if the lockfile is outdated
package_json.manager.install(frozen: true)
```

| Option   | Description                              |
| -------- | ---------------------------------------- |
| `frozen` | Fail if the lockfile needs to be updated |

#### Generating the `install` command for native scripts and advanced calls

```ruby
# returns an array of strings that make up the desired operation
native_install_command = package_json.manager.native_install_command

# runs the command with extra environment variables
Kernel.system({ "HELLO" => "WORLD" }, *native_install_command)

append_to_file "bin/ci-run" do
  <<~CMD
    echo "* ******************************************************"
    echo "* Installing JS dependencies"
    echo "* ******************************************************"
    #{native_install_command.join(" ")}
  CMD
end
```

| Option   | Description                              |
| -------- | ---------------------------------------- |
| `frozen` | Fail if the lockfile needs to be updated |

#### Adding dependencies

```ruby
# adds axios as a production dependency
package_json.manager.add(["axios"])

# adds eslint and prettier as dev dependencies
package_json.manager.add(["eslint", "prettier"], type: :dev)

# adds dotenv-webpack v6 as a production dependency
package_json.manager.add(["dotenv-webpack@^6"])

# adds react-on-rails with exact version (no ^ or ~)
package_json.manager.add(["react-on-rails@16.0.0"], exact: true)
```

| Option  | Description                                                                                 |
| ------- | ------------------------------------------------------------------------------------------- |
| `type`  | The type to add the dependencies as; either `:production` (default), `:dev`, or `:optional` |
| `exact` | If true, saves packages with exact versions (no `^` or `~` prefix)                          |

#### Removing dependencies

```ruby
# removes the axios package
package_json.manager.remove(["axios"])
```

#### Run a script

```ruby
# runs the "test" script
package_json.manager.run("test")

# runs the "test" script, passing it "--coverage path/to/my/test.js" as the argument
package_json.manager.run("test", ["--coverage", "path/to/my/test.js"])

# runs the "lint" script, passing it "--fix" as the argument and telling the package manager to be silent
package_json.manager.run("lint", ["--fix"], silent: true)
```

| Option   | Description                              |
| -------- | ---------------------------------------- |
| `silent` | Suppress output from the package manager |

#### Generating a `run` command for native scripts and advanced calls

```ruby
native_run_command = package_json.manager.native_run_command("test", ["--coverage"])

# runs the command with extra environment variables
Kernel.system({ "HELLO" => "WORLD" }, *native_run_command)

append_to_file "bin/ci-run" do
  <<~CMD
    echo "* ******************************************************"
    echo "* Running JS tests"
    echo "* ******************************************************"
    #{native_run_command.join(" ")}
  CMD
end
```

| Option   | Description                              |
| -------- | ---------------------------------------- |
| `silent` | Suppress output from the package manager |

#### Generating a `exec` command for native scripts and advanced calls

```ruby
native_exec_command = package_json.manager.native_exec_command("webpack", ["serve"])

# runs the command with extra environment variables
Kernel.system({ "HELLO" => "WORLD" }, *native_exec_command)

append_to_file "bin/webpack-webpack" do
  <<~CMD
    echo "* ******************************************************"
    echo "* Serving assets via webpack
    echo "* ******************************************************"
    #{native_exec_command.join(" ")}
  CMD
end
```

> **Note**
>
> Since Yarn Classic doesn't provide a native `exec` command, `yarn bin` is used
> instead to identify where the package command should be within `node_modules`.
>
> For other package managers, their native `exec` command is used with the flags
> necessary to enforce the package command is only executed if the package is
> installed locally.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run
`rake spec` to run the tests. You can also run `bin/console` for an interactive
prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To
release a new version, update the version number in `version.rb`, and then tag
the commit with the version prefixed with a `v`, which will trigger the release
workflow to publish the new version to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at
https://github.com/shakacode/package_json. This project is intended to be a
safe, welcoming space for collaboration, and contributors are expected to adhere
to the
[code of conduct](https://github.com/shakacode/package_json/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the
[MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the PackageJson project's codebases, issue trackers,
chat rooms and mailing lists is expected to follow the
[code of conduct](https://github.com/shakacode/package_json/blob/main/CODE_OF_CONDUCT.md).
