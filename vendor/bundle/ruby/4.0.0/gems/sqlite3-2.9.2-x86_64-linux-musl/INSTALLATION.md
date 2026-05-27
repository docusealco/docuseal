
# Installation and Using SQLite3 extensions

This document will help you install the `sqlite3` ruby gem. It also contains instructions on loading database extensions and building against drop-in replacements for sqlite3.

## Installation

### Native Gems (recommended)

In v2.5.0 and later, native (precompiled) gems are available for recent Ruby versions on these platforms:

- `aarch64-linux-gnu` (requires: glibc >= 2.29)
- `aarch64-linux-musl`
- `arm-linux-gnu` (requires: glibc >= 2.29)
- `arm-linux-musl`
- `arm64-darwin`
- `x64-mingw-ucrt`
- `x86-linux-gnu` (requires: glibc >= 2.29)
- `x86-linux-musl`
- `x86_64-darwin`
- `x86_64-linux-gnu` (requires: glibc >= 2.29)
- `x86_64-linux-musl`

⚠ Musl linux users should update to Bundler >= 2.5.6 to avoid https://github.com/rubygems/rubygems/issues/7432

If you are using one of these Ruby versions on one of these platforms, the native gem is the recommended way to install sqlite3-ruby.

For example, on a linux system running Ruby 3.4:

``` text
$ ruby -v
ruby 3.4.7 (2025-10-08 revision 7a5688e2a2) +PRISM [x86_64-linux]

$ time gem install sqlite3
Fetching sqlite3-2.8.1-x86_64-linux-gnu.gem
Successfully installed sqlite3-2.8.1-x86_64-linux-gnu
1 gem installed

real    0m1.273s
user    0m0.496s
sys     0m0.078s
```

#### Avoiding the precompiled native gem

The maintainers strongly urge you to use a native gem if at all possible. It will be a better experience for you and allow us to focus our efforts on improving functionality rather than diagnosing installation issues.

If you're on a platform that supports a native gem but you want to avoid using it in your project, do one of the following:

- If you're not using Bundler, then run `gem install sqlite3 --platform=ruby`
- If you are using Bundler
  - version 2.3.18 or later, you can specify [`gem "sqlite3", force_ruby_platform: true`](https://bundler.io/v2.3/man/gemfile.5.html#FORCE_RUBY_PLATFORM)
  - version 2.1 or later, then you'll need to run `bundle config set force_ruby_platform true`
  - version 2.0 or earlier, then you'll need to run `bundle config force_ruby_platform true`


### Compiling the source gem

If you are on a platform or version of Ruby that is not covered by the Native Gems, then the vanilla "ruby platform" (non-native) gem will be installed by the `gem install` or `bundle` commands.


#### Packaged libsqlite3

By default, as of v1.5.0 of this library, the latest available version of libsqlite3 is packaged with the gem and will be compiled and used automatically. This takes a bit longer than the native gem, but will provide a modern, well-supported version of libsqlite3.

⚠ A prerequisite to build the gem with the packaged sqlite3 is that you must have `pkgconf` installed.

For example, on a linux system running Ruby 2.5:

``` text
$ ruby -v
ruby 2.5.9p229 (2021-04-05 revision 67939) [x86_64-linux]

$ time gem install sqlite3
Building native extensions. This could take a while...
Successfully installed sqlite3-1.5.0
1 gem installed

real    0m20.620s
user    0m23.361s
sys     0m5.839s
```

##### Controlling compilation flags for sqlite

Upstream sqlite allows for the setting of some parameters at compile time. If you're an expert and would like to set these, you may do so at gem install time in two different ways ...

**If you're installing the gem using `gem install`** then you can pass in these compile-time flags like this:

``` sh
gem install sqlite3 --platform=ruby -- \
  --with-sqlite-cflags="-DSQLITE_DEFAULT_CACHE_SIZE=9999 -DSQLITE_DEFAULT_PAGE_SIZE=4444"
```

or the equivalent:

``` sh
CFLAGS="-DSQLITE_DEFAULT_CACHE_SIZE=9999 -DSQLITE_DEFAULT_PAGE_SIZE=4444" \
  gem install sqlite3 --platform=ruby
```

**If you're installing the gem using `bundler`** then you should first pin the gem to the "ruby" platform gem, so that you are compiling from source:

``` ruby
# Gemfile
gem "sqlite3", force_ruby_platform: true # requires bundler >= 2.3.18
```

and then set up a bundler config parameter for `build.sqlite3`:

``` sh
bundle config set build.sqlite3 \
  "--with-sqlite-cflags='-DSQLITE_DEFAULT_CACHE_SIZE=9999 -DSQLITE_DEFAULT_PAGE_SIZE=4444'"
```

NOTE the use of single quotes within the double-quoted string to ensure the space between compiler flags is interpreted correctly. The contents of your `.bundle/config` file should look like:

``` yaml
---
BUNDLE_BUILD__SQLITE3: "--with-sqlite-cflags='-DSQLITE_DEFAULT_CACHE_SIZE=9999 -DSQLITE_DEFAULT_PAGE_SIZE=4444'"
```


#### System libsqlite3

If you would prefer to build the sqlite3-ruby gem against your system libsqlite3, which requires that you install libsqlite3 and its development files yourself, you may do so by using the `--enable-system-libraries` flag at gem install time.

PLEASE NOTE:

- you must avoid installing a precompiled native gem (see [previous section](#avoiding-the-precompiled-native-gem))
- only versions of libsqlite3 `>= 3.5.0` are supported,
- and some library features may depend on how your libsqlite3 was compiled.

For example, on a linux system running Ruby 2.5:

``` text
$ time gem install sqlite3 -- --enable-system-libraries
Building native extensions with: '--enable-system-libraries'
This could take a while...
Successfully installed sqlite3-1.5.0
1 gem installed

real    0m4.234s
user    0m3.809s
sys     0m0.912s
```

If you're using bundler, you can opt into system libraries like this:

``` sh
bundle config build.sqlite3 --enable-system-libraries
```

If you have sqlite3 installed in a non-standard location, you may need to specify the location of the include and lib files by using `--with-sqlite-include` and `--with-sqlite-lib` options (or a `--with-sqlite-dir` option, see [MakeMakefile#dir_config](https://ruby-doc.org/stdlib-3.1.1/libdoc/mkmf/rdoc/MakeMakefile.html#method-i-dir_config)). If you have pkg-config installed and configured properly, this may not be necessary.

``` sh
gem install sqlite3 -- \
  --enable-system-libraries \
  --with-sqlite3-include=/opt/local/include \
  --with-sqlite3-lib=/opt/local/lib
```


#### System libsqlcipher

If you'd like to link against a system-installed libsqlcipher, you may do so by using the `--with-sqlcipher` flag:

``` text
$ time gem install sqlite3 -- --with-sqlcipher
Building native extensions with: '--with-sqlcipher'
This could take a while...
Successfully installed sqlite3-1.5.0
1 gem installed

real    0m4.772s
user    0m3.906s
sys     0m0.896s
```

If you have sqlcipher installed in a non-standard location, you may need to specify the location of the include and lib files by using `--with-sqlite-include` and `--with-sqlite-lib` options (or a `--with-sqlite-dir` option, see [MakeMakefile#dir_config](https://ruby-doc.org/stdlib-3.1.1/libdoc/mkmf/rdoc/MakeMakefile.html#method-i-dir_config)). If you have pkg-config installed and configured properly, this may not be necessary.


## Using SQLite3 extensions

### How do I load a sqlite extension?

Some add-ons are available to sqlite as "extensions". The instructions that upstream sqlite provides at https://www.sqlite.org/loadext.html are the canonical source of advice, but here's a brief example showing how you can do this with the `sqlite3` ruby gem.

In this example, I'll be loading the ["spellfix" extension](https://www.sqlite.org/spellfix1.html):

``` text
# download spellfix.c from somewherehttp://www.sqlite.org/src/finfo?name=ext/misc/spellfix.c
$ wget https://raw.githubusercontent.com/sqlite/sqlite/master/ext/misc/spellfix.c
spellfix.c                     100%[=================================================>] 100.89K  --.-KB/s    in 0.09s

# follow instructions at https://www.sqlite.org/loadext.html
# (you will need sqlite3 development packages for this)
$ gcc -g -fPIC -shared spellfix.c -o spellfix.o

$ ls -lt
total 192
-rwxrwxr-x 1 flavorjones flavorjones  87984 2023-05-24 10:44 spellfix.o
-rw-rw-r-- 1 flavorjones flavorjones 103310 2023-05-24 10:43 spellfix.c
```

Then, in your application, use that `spellfix.o` file like this:

``` ruby
require "sqlite3"

db = SQLite3::Database.new(':memory:')
db.enable_load_extension(true)
db.load_extension("/path/to/sqlite/spellfix.o")
db.execute("CREATE VIRTUAL TABLE demo USING spellfix1;")
```

### How do I use my own sqlite3 shared library?

Some folks have strong opinions about what features they want compiled into sqlite3; or may be using a package like SQLite Encryption Extension ("SEE"). This section will explain how to get your Ruby application to load that specific shared library.

If you've installed your alternative as an autotools-style installation, the directory structure will look like this:

```
/opt/sqlite3
├── bin
│   └── sqlite3
├── include
│   ├── sqlite3.h
│   └── sqlite3ext.h
├── lib
│   ├── libsqlite3.a
│   ├── libsqlite3.la
│   ├── libsqlite3.so -> libsqlite3.so.0.8.6
│   ├── libsqlite3.so.0 -> libsqlite3.so.0.8.6
│   ├── libsqlite3.so.0.8.6
│   └── pkgconfig
│       └── sqlite3.pc
└── share
    └── man
        └── man1
            └── sqlite3.1
```

You can build this gem against that library like this:

```
gem install sqlite3 --platform=ruby -- \
  --enable-system-libraries \
  --with-opt-dir=/opt/sqlite
```

Explanation:

- use `--platform=ruby` to avoid the precompiled native gems (see the README)
- the `--` separates arguments passed to "gem install" from arguments passed to the C extension builder
- use `--enable-system-libraries` to avoid the vendored sqlite3 source
- use `--with-opt-dir=/path/to/installation` to point the build process at the desired header files and shared object files

Alternatively, if you've simply downloaded an "amalgamation" and so your compiled library and header files are in arbitrary locations, try this more detailed command:

```
gem install sqlite3 --platform=ruby -- \
  --enable-system-libraries \
  --with-opt-include=/path/to/include \
  --with-opt-lib=/path/to/lib
```

