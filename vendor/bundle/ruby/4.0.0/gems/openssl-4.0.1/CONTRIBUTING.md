# Contributing to Ruby OpenSSL

Thank you for your interest in contributing to Ruby OpenSSL!

This documentation provides an overview how you can contribute.

## Bugs and feature requests

Bugs and feature requests are tracked on [GitHub].

If you think you found a bug, file a ticket on GitHub. Please DO NOT report
security issues here, there is a separate procedure which is described on
["Security at ruby-lang.org"][Ruby Security].

When reporting a bug, please make sure you include:

* Ruby version (`ruby -v`)
* `openssl` gem version (`gem list openssl` and `OpenSSL::VERSION`)
* OpenSSL library version (`OpenSSL::OPENSSL_VERSION`)
* A sample file that illustrates the problem or link to the repository or
  gem that is associated with the bug.

There are a number of unresolved issues and feature requests for openssl that
need review. Before submitting a new ticket, it is recommended to check
[known issues][Issues].

## Submitting patches

Patches are also very welcome!

Please submit a [pull request][Compare changes] with your changes.

Make sure that your branch does:

* Have good commit messages
* Follow Ruby's coding style ([Developer-How-To][Ruby Developer-How-To])
* Pass the test suite successfully (see "Testing")

## Testing

We have a test suite!

Test cases are located under the [`test/openssl`][GitHub test/openssl]
directory.

You can run it with the following three commands:

```
$ bundle install # installs rake-compiler, test-unit, ...
$ bundle exec rake compile
$ bundle exec rake test
```

### With different versions of OpenSSL

Ruby OpenSSL supports various versions of the OpenSSL library. The test suite
needs to pass on all supported combinations.

If you want to test, debug, report an issue, or contribute to the Ruby OpenSSL
or [the OpenSSL project][OpenSSL] in the non-FIPS or the
[FIPS][OpenSSL README-FIPS] case, compiling OpenSSL from the source by yourself
is a good practice.

The following steps are tested in Linux and GCC environment. You can adjust the
commands in the steps for a different environment.

To download the OpenSSL source from the Git repository, you can run the following
commands:

```
$ git clone https://github.com/openssl/openssl.git
$ cd openssl
```

You see the `master` branch used as a development branch. Testing against the
latest OpenSSL master branch is a good practice to report an issue to the
OpenSSL project.

```
$ git branch | grep '^*'
* master
```

If you test against the latest stable branch, you can run the following command.
In this example, the `openssl-3.1` branch is the stable branch of OpenSSL 3.1
series.

```
$ git checkout openssl-3.1
```

To configure OpenSSL, you can run the following commands.

In this example, we use the `OPENSSL_DIR` environment variable to specify the
OpenSSL installed directory for convenience. Including the commit hash in the
directory name is a good practice.

```
$ git rev-parse --short HEAD
0bf18140f4

$ OPENSSL_DIR=$HOME/.openssl/openssl-fips-debug-0bf18140f4
```

The following configuration options are useful in this case.
You can check [OpenSSL installation document][OpenSSL INSTALL] for details.

* `enable-fips`: Add an option to run with the OpenSSL FIPS module.
* `enable-trace`: Add an option to enabling tracing log. You can trace logs by
  implementing a code. See the man page [OSSL_TRACE(3)][OpenSSL OSSL_TRACE] for
  details.
* compiler flags
  * `-Wl,-rpath,$(LIBRPATH)`: Set the runtime shared library path to run the
    `openssl` command without the `LD_LIBRARY_PATH`. You can check
    [this document][OpenSSL NOTES-UNIX] for details.
  * `-O0 -g3 -ggdb3 -gdwarf-5`: You can set debugging compiler flags.

```
$ ./Configure \
  --prefix=$OPENSSL_DIR \
  --libdir=lib \
  enable-fips \
  enable-trace \
  '-Wl,-rpath,$(LIBRPATH)' \
  -O0 -g3 -ggdb3 -gdwarf-5
$ make -j4
$ make install
```

To print installed OpenSSL version, you can run the following command:

```
$ $OPENSSL_DIR/bin/openssl version
OpenSSL 3.2.0-alpha3-dev  (Library: OpenSSL 3.2.0-alpha3-dev )
```

Change the current working directory into Ruby OpenSSL's source directory.

To compile Ruby OpenSSL, you can run the following commands:

Similarly to when installing `openssl` gem via the `gem` command, you can pass a
`--with-openssl-dir` argument to `rake compile` to specify the OpenSSL library
 to build against.

* `MAKEFLAGS="V=1"`: Enable the compiler command lines to print in
  the log.
* `RUBY_OPENSSL_EXTCFLAGS`: Set extra compiler flags to compile Ruby OpenSSL.

```
$ bundle exec rake clean
$ MAKEFLAGS="V=1" \
  RUBY_OPENSSL_EXTCFLAGS="-O0 -g3 -ggdb3 -gdwarf-5" \
  bundle exec rake compile -- --with-openssl-dir=$OPENSSL_DIR
```

#### Testing normally in non-FIPS case

To test Ruby OpenSSL, you can run the following command:

```
$ bundle exec rake test
```

#### Testing in FIPS case

To use OpenSSL 3.0 or later versions in a FIPS-approved manner, you must load the
`fips` and `base` providers, and also use the property query `fips=yes`. The
property query is used when fetching cryptographic algorithm implementations.
This must be done at the startup of a process to avoid implicitly loading the
`default` provider which has the non-FIPS cryptographic algorithm
implementations. See also the man page [fips_module(7)][OpenSSL fips_module].

You can set this in your OpenSSL configuration file by either appropriately
modifying the default OpenSSL configuration file located at
`OpenSSL::Config::DEFAULT_CONFIG_FILE` or temporarily overriding it with the
`OPENSSL_CONF` environment variable.

In this example, we explain on the latter way.

You can create a OpenSSL FIPS config `openssl_fips.cnf` file based on the
`openssl_fips.cnf.tmpl` file in this repository, and replacing the placeholder
`OPENSSL_DIR` with your OpenSSL installed directory.

```
$ sed -e "s|OPENSSL_DIR|$OPENSSL_DIR|" tool/openssl_fips.cnf.tmpl | \
  tee $OPENSSL_DIR/ssl/openssl_fips.cnf
```

You can see the base and fips providers by running the following command if you
setup the OpenSSL FIPS config file properly.

```
$ OPENSSL_CONF=$OPENSSL_DIR/ssl/openssl_fips.cnf \
  $OPENSSL_DIR/bin/openssl list -providers
Providers:
  base
    name: OpenSSL Base Provider
    version: 3.2.0
    status: active
  fips
    name: OpenSSL FIPS Provider
    version: 3.2.0
    status: active
```

You can run the current tests in the FIPS module case used in the GitHub
Actions file `test.yml` explained in a later sentence.

```
$ OPENSSL_CONF=$OPENSSL_DIR/ssl/openssl_fips.cnf \
  bundle exec rake test_fips
```

You can also run the all the tests in the FIPS module case. You see many
failures. We are working in progress to fix the failures. Your contribution is
welcome.

```
$ OPENSSL_CONF=$OPENSSL_DIR/ssl/openssl_fips.cnf \
  TEST_RUBY_OPENSSL_FIPS_ENABLED=true \
  bundle exec rake test
```

The GitHub Actions workflow file [`test.yml`][GitHub test.yml] contains useful
information for building OpenSSL/LibreSSL and testing against them.

## Debugging

You can use the `OpenSSL.debug = true` to print additional error strings.

## Relation with Ruby source tree

After Ruby 2.3, `ext/openssl` was converted into a "default gem", a library
which ships with standard Ruby builds but can be upgraded via RubyGems. This
means the development of this gem has migrated to a [separate
repository][GitHub] and will be released independently.

The version included in the Ruby source tree (trunk branch) is synchronized with
the latest release.

## Release policy

Bug fixes (including security fixes) will be made only for the version series
included in a stable Ruby release.

## Security

If you discovered a security issue, please send us in private, using the
security issue handling procedure for Ruby core.

You can either use [HackerOne] or send an email to security@ruby-lang.org.

Please see [Security][Ruby Security] page on ruby-lang.org website for details.

Reported problems will be published after a fix is released.

_Thanks for your contributions!_

  _\- The Ruby OpenSSL team_

[GitHub]: https://github.com/ruby/openssl
[Issues]: https://github.com/ruby/openssl/issues
[Compare changes]: https://github.com/ruby/openssl/compare
[GitHub test/openssl]: https://github.com/ruby/openssl/tree/master/test/openssl
[GitHub test.yml]: https://github.com/ruby/openssl/tree/master/.github/workflows/test.yml
[Ruby Developer-How-To]: https://github.com/ruby/ruby/wiki/Developer-How-To
[Ruby Security]: https://www.ruby-lang.org/en/security/
[HackerOne]: https://hackerone.com/ruby
[OpenSSL]: https://www.openssl.org/
[OpenSSL INSTALL]: https://github.com/openssl/openssl/blob/master/INSTALL.md
[OpenSSL README-FIPS]: https://github.com/openssl/openssl/blob/master/README-FIPS.md
[OpenSSL NOTES-UNIX]: https://github.com/openssl/openssl/blob/master/NOTES-UNIX.md
[OpenSSL OSSL_TRACE]: https://www.openssl.org/docs/manmaster/man3/OSSL_TRACE.html
[OpenSSL fips_module]: https://www.openssl.org/docs/manmaster/man7/fips_module.html
