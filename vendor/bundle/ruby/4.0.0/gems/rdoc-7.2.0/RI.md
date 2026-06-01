# `ri`: Ruby Information

`ri` (<b>r</b>uby <b>i</b>nformation) is the Ruby command-line utility
that gives fast and easy on-line access to Ruby documentation.

`ri` can show documentation for Ruby itself and for its installed gems:

- A **class** or **module**:
  text associated with the class or module definition
  in a source file (`.rb` or `.c`).
- One or more **methods**:
  text associated with method definitions
  in source files (`.rb` and `.c`).
- A **page**:
  text from a stand-alone documentation file
  (`.rdoc` or  `.md`, or sometimes other).

Examples (output omitted):

```sh
$ ri Hash             # Document for class Hash.
$ ri Array#sort       # Document for instance method sort in class Array.
$ ri read             # Documents for methods ::read and #read in all classes and modules.
$ ri ruby:dig_methods # Document for page dig_methods.
```

`ri` can also show lists of:

- **classes** and **modules**:
  full or partial list.
- **pages**:
  for Ruby or for an installed gem.

Examples (output omitted):

```sh
$ ri --list # List of classes and modules.
$ ri ruby:  # List of Ruby pages.
```

## Why `ri`?

Using `ri` may have advantages over using
the [Ruby online documentation](https://docs.ruby-lang.org/en/master):

- The `ri` documentation is always available, even when you do not have internet access
  (think: airplane mode).
- If you are working in a terminal window, typing `ri _whatever_` (or just `ri`)
  may be faster than navigating to a browser window and searching for documentation.
- If you are working in an
  [irb \(interactive Ruby\)](https://ruby.github.io/irb/index.html)
  session, you _already_ have immediate access to `ri`:
  just type `'show_doc'`.

## Modes

There are two `ri` modes:

- <i>Static mode</i>:
  In general, `ri` responds in its static mode
  if a _name_ is given;
  it shows results and exits (as in the examples above).
  See [Static Mode][1].
- <i>Interactive mode</i>:
  In general, `ri` enters its interactive mode
  if no _name_ is given;
  in interactive mode, `ri` shows results and waits for another command:

    ```sh
    $ ri
    Enter the method name you want to look up.
    You can use tab to autocomplete.
    Enter a blank line to exit.
    >>
    ```

    See [Interactive Mode][2].

## Names

In both modes, static and interactive,
`ri` responds to an input _name_ that specifies what is to be displayed:
a document, multiple documents, or other information:

- Static mode (in the shell): type `'ri _name_'`;
  examples (output omitted):

    ```sh
    $ ri File
    $ ri IO#readlines
    $ ri ruby:
    ```

- Interactive mode (already in `ri`): just type the _name_;
  examples (output omitted):

    ```sh
    $ ri
    Enter the method name you want to look up.
    You can use tab to autocomplete.
    Enter a blank line to exit.
    >> File
    >> IO#readlines
    >> ruby:
    ```

### Names for Class and Module Documents

These example `ri` commands cite names for class and module documents
(see [details and examples][3]):

| Command                      | Shows                                                      |
|------------------------------|------------------------------------------------------------|
| ri File                      | Document for Ruby class File.                              |
| ri File::Stat                | Document for Ruby nested class File::Stat.                 |
| ri Enumerable                | Document for Ruby module Enumerable.                       |
| ri Arr                       | Document for Ruby class Array (unique initial characters). |
| ri Nokogiri::HTML4::Document | Document for gem class Nokogiri::HTML4::Document.          |
| ri Nokogiri                  | Document for gem module Nokogiri.                          |
<br>

If [option \\--all][4]
is in effect, documents for the methods in the named class or module
are included in the display.

### Names for Method Documents

These example `ri` commands cite names for method documents
(see [details and examples][5]):

| Command                              | Shows                                                                            |
|--------------------------------------|----------------------------------------------------------------------------------|
| ri IO::readlines                     | Document for Ruby class method IO::readlines.                                    |
| ri IO#readlines                      | Document for Ruby instance method IO::readlines.                                 |
| ri IO.readlines                      | Documents for Ruby instance method IO::readlines and class method IO::readlines. |
| ri ::readlines                       | Documents for all class methods ::readlines.                                     |
| ri #readlines                        | Documents for all instance methods #readlines.                                   |
| ri .readlines, ri readlines          | Documents for class methods ::readlines and instance methods #readlines.         |
| ri Nokogiri::HTML4::Document::parse  | Document for gem class method Nokogiri::HTML4::Document::parse.                  |
| ri Nokogiri::HTML4::Document#fragment | Document for gem instance method Nokogiri::HTML4::Document#fragment.            |
<br>

### Names for Page Documents

These example `ri` commands cite names for page documents
(see [details and examples][6]):

| Command                        | Shows                                            |
|--------------------------------|--------------------------------------------------|
| ri ruby:syntax/assignment.rdoc | Document for Ruby page assignment.               |
| ri ruby:syntax/assignment      | Same document, if no other syntax/assignment.*.  |
| ri ruby:assignment             | Same document, if no other */assignment.*.       |
| ri nokogiri:README.md          | Document for page README.md.                     |
<br>

### Names for Lists

These example `ri` commands cite names for lists
(see [details and examples][7]):

| Command       | Shows                   |
|---------------|-------------------------|
| ri ruby:      | List of Ruby pages.     |
| ri nokogiri:  | List of Nokogiri pages. |
<br>

There are more lists available;
see [option \\--list][8].

## Pro Tips

### `ri` at the Ready

If you are a frequent `ri` user,
you can save time by keeping open a dedicated command window
with either of:

- A running [interactive ri][2] session.
- A running [irb session][9];
  type `'show_doc'` to enter `ri`, newline to exit.

When you switch to that window, `ri` is ready to respond quickly,
without the performance overhead of re-reading `ri` sources.

### Output Filters

The `pager` value actually need not be simply the path to an executable;
it's actually a full-fledged command line,
and so may include not only the executable path,
but also whatever options and arguments that executable accepts.

You can, for example, set the pager value to `'grep . | less'`,
which will exclude blank lines (thus saving screen space)
before piping the result to `less`;
example (output omitted):

```sh
$ RI_PAGER="grep . | less" ri Array
```

See the documentation for your chosen pager programs
(e.g, type `'grep --help'`, `'less --help'`).

### Links  in `ri` Output

#### Implicit Link

When you see:

- `'IO::readlines'`, `'IO#readlines'`, `'IO.readlines'`:
  use that same text as the _name_ in an `ri` command.

    Examples (output omitted):

    ```sh
    $ ri IO::readlines
    $ ri IO#readlines
    $ ri IO.readlines
    ```

- `'#read'`, `'::read'`, `'.read'`:
  you're likely already in the `ri` document for a class or module,
  or for a method in a class or module;
  use that same text with the name of the class or module (such as `'File'`)
  as the _name_ in an `ri` command.

    Examples (output omitted):

    ```sh
    $ ri File::read
    $ ri File#read
    $ ri File.read
    ```

#### Explicit Link

When you see:

- `'{Dig Methods}[rdoc-ref:doc/dig_methods.rdoc]'`:
   use the trailing part of the `'[rdoc-ref:doc/'` in an `ri` command
   for a Ruby document.

    Example (output omitted):

    ```sh
    $ ri ruby:dig_methods.rdoc
    ```

- `'{Table (information)}[https://en.wikipedia.org/wiki/Table_(information)]'`:
  go to the given URL in your browser.

## About the Examples

- `ri` output can be large;
  to save space, an example may pipe it to one of these:

    - [head](https://www.man7.org/linux/man-pages/man1/head.1.html): leading lines only.
    - [tail](https://www.man7.org/linux/man-pages/man1/tail.1.html): trailing lines only.
    - [wc -l](https://www.man7.org/linux/man-pages/man1/wc.1.html): line count only.
    - [grep](https://www.man7.org/linux/man-pages/man1/grep.1.html): selected lines only.

- An example that involves a gem assumes that gems `nokogiri` and `minitest` are installed.

## `ri` Documents

This section outlines what you can expect to find
in the `ri` document for a class, module, method, or page.

See also:

- [Pager][10].
- [Links in ri Output][11].

### Class and Module Documents

The document for a class or module shows:

- The class or module name, along with its parent class if any.
- Where it's defined (Ruby core or gem).
- When each exists:

    - The names of its included modules.
    - The text of its embedded documentation.
    - Its constants.
    - Its class methods.
    - Its instance methods.

Examples:

- Ruby class `Array`:

    ```sh
    $ ri Array | head
    = Array < Object

    ------------------------------------------------------------------------
    = Includes:
      Enumerable (from ruby core)

    (from ruby core)
    ------------------------------------------------------------------------
    An Array is an ordered, integer-indexed collection of objects, called
    elements.  Any object may be an Array element.
    ```

- Gem module `Nokogiri`:

    ```sh
    $ ri Nokogiri | head
    = Nokogiri

    (from gem nokogiri-1.16.2-x86_64-linux)
    ------------------------------------------------------------------------

    Nokogiri parses and searches XML/HTML very quickly, and also has
    correctly implemented CSS3 selector support as well as XPath 1.0
    support.

    Parsing a document returns either a Nokogiri::XML::Document, or a
    ```

The document typically includes certain headings,
which may be useful for searching:

```sh
$ ri IO | grep "^= "
= IO < Object
= Includes:
= Constants:
= Class methods:
= Instance methods:
```

### Method Documents

The document for a method includes:

- The source of the method: `'(from ruby core)'` or `'(from gem _gem_)'`.
- The calling sequence(s) for the method.
- The text of its embedded documentation (if it exists).

Examples:

```sh
$ ri IO#read | head
= IO#read

(from ruby core)
------------------------------------------------------------------------
ios.read([length [, outbuf]])    -> string, outbuf, or nil

------------------------------------------------------------------------

Reads length bytes from the I/O stream.
```

```sh
$ ri Nokogiri::parse | head
= Nokogiri::parse

(from gem nokogiri-1.16.2-x86_64-linux)
------------------------------------------------------------------------
  parse(string, url = nil, encoding = nil, options = nil) { |doc| ... }

------------------------------------------------------------------------

Parse an HTML or XML document.  string contains the document.
```

The output for a _name_ that cites methods includes the document
for each found implementation;
the number of such implementations depends on the _name_:

- Within a class:

    Each of these commands shows documents
    for methods in Ruby class `IO` (output omitted):

    ```sh
    $ ri IO::readlines # Class method ::readlines.
    $ ri IO#readlines  # Instance method #readlines.
    $ ri IO.readlines  # Both of above.
    ```

- In all classes:

    Each of these commands shows documents
    for methods in all classes (output omitted):

    ```sh
    $ ri ::readlines   # Class method ::readlines.
    $ ri \#readlines   # Instance method #readlines.
    $ ri .readlines    # Both of above.
    ```

    For these all-classes commands,
    the output is organized into sections,
    one for each found method (output filtered to show sections):

    ```sh
    $ ri ::readlines | grep "= Implementation"
    === Implementation from CSV
    === Implementation from IO
    ```

    ```sh
    $ ri \#readlines | grep "= Implementation"
    === Implementation from ARGF
    === Implementation from CSV
    === Implementation from IO
    === Implementation from Kernel
    === Implementation from Buffering
    === Implementation from Pathname
    === Implementation from StringIO
    === Implementation from GzipReader
    ```

    ```sh
    $ ri .readlines | grep "= Implementation"
    === Implementation from ARGF
    === Implementation from CSV
    === Implementation from CSV
    === Implementation from IO
    === Implementation from IO
    === Implementation from Kernel
    === Implementation from Buffering
    === Implementation from Pathname
    === Implementation from StringIO
    === Implementation from GzipReader
    ```

### Page Documents

The document for a Ruby page is the text from the `.rdoc` or `.md` source
for that page:

```sh
$ ri ruby:dig_methods | head
= Dig Methods

Ruby's dig methods are useful for accessing nested data structures.

Consider this data:
  item = {
    id: "0001",
    type: "donut",
    name: "Cake",
    ppu: 0.55,
```

The document for a gem page is whatever the gem has generated
for the page:

```sh
$ ri minitest:README | head
= minitest/{test,spec,mock,benchmark}

home:
  https://github.com/minitest/minitest

bugs:
  https://github.com/minitest/minitest/issues

rdoc:
  https://docs.seattlerb.org/minitest
```

## `ri` Lists

The list of Ruby pages is available via _name_ `'ruby:'`:

```sh
$ ri ruby: | head
= Pages in ruby core

CONTRIBUTING.md
COPYING
COPYING.ja
LEGAL
NEWS-1.8.7
NEWS-1.9.1
NEWS-1.9.2
NEWS-1.9.3
```

```sh
$ ri ruby: | tail
syntax/control_expressions.rdoc
syntax/exceptions.rdoc
syntax/literals.rdoc
syntax/methods.rdoc
syntax/miscellaneous.rdoc
syntax/modules_and_classes.rdoc
syntax/pattern_matching.rdoc
syntax/precedence.rdoc
syntax/refinements.rdoc
win32/README.win32
```

The list of gem pages is available via _name_ `'_gem_name_'`:

```sh
$ ri nokogiri: | head
= Pages in gem nokogiri-1.16.2-x86_64-linux

README.md
lib/nokogiri/css/tokenizer.rex
```

See also:

- [Option \\--list][8]:
  lists classes and modules.
- [Option \\--list-doc-dirs][12]:
  lists `ri` source directories.

## `ri` Information

With certain options,
an `ri` command may display information other than documents or lists:

- [Option \\--help or -h][13]:
  Shows `ri` help text.
- [option \\--version or -v][14]:
  Shows `ri` version.
- [Option \\--dump=FILEPATH][15]:
  Shows dump of `ri` cache file at the given filepath.

## Static Mode

In static mode, `ri` shows a response and exits.

In general, `ri` responds in static mode
if the command gives a _name_:

```sh
$ ri Array | head
= Array < Object

------------------------------------------------------------------------
= Includes:
Enumerable (from ruby core)

(from ruby core)
------------------------------------------------------------------------
An Array is an ordered, integer-indexed collection of objects, called
elements.  Any object may be an Array element.
```

`ri` also responds in static mode when certain options are given,
even when no _name_ is given;
see [ri Information][16].

## Interactive Mode

In general, `ri` responds to a command in interactive mode
if the command has no arguments:

```sh
$ ri
Enter the method name you want to look up.
You can use tab to autocomplete.
Enter a blank line to exit.
>>

```

A command in interactive mode are similar to one in static mode,
except that it:

- Omits command word `ri`; you just type the _name_.
- Omits options; in interactive mode the only options in effect
  are those taken from environment variable `RI`.
  See [Options][17].
- Supports tab auto-completion for the name of a class, module, or method;
  when, for example, you type `"Arr\t"` (here `"\t` represents the tab character),
  `ri` "completes" the text as `'Array '`.

See also [ri at the Ready][18].

## Pager

Because `ri` output is often large,
`ri` by default pipes it to a _pager_,
which is the program whose name is the first-found among:

- The value of `ENV['RI_PAGER']`.
- The value of `ENV['PAGER']`.
- `'pager'`.
- `'less'`.
- `'more'`.

If none is found, the output goes directly to `$stdout`, with no pager.

If you set environment variable `RI_PAGER` or `PAGER`,
its value should be the name of an executable program
that will accept the `ri` output (such as `'pager'`, `'less'`, or `'more'`).

See also [Output Filters][19].

## Options

Options may be given on the `ri` command line;
those should be whitespace-separated, and must precede the given _name_, if any.

Options may also be specified in environment variable `RI`;
those should also be whitespace-separated.

An option specified in environment variable `RI`
may be overridden by an option on the `ri` command line:

```sh
$ RI="--all" ri Array | wc -l
4224
$ RI="--all" ri --no-all Array | wc -l
390
```

### Source Directories Options

#### Options `--doc-dir=DIRPATH`, `-d DIRPATH`

Option `--doc-dir=DIRPATH` (aliased as `-d`) adds the given directory path
to the beginning of the array of `ri` source directory paths:

```sh
$ ri --doc-dir=/tmp --list-doc-dirs | head -1
/tmp
```

#### Options `--gems`, `--no-gems`

Option `--gems` (the default) specifies that documents from installed gems
may be included;
option `--no-gems` may be used to exclude them:

```sh
$ ri --list | wc -l
1417
$ ri --list --no-gems| wc -l
1262
```

#### Options `--home`, `--no-home`

Option `--home` (the default) specifies that `ri` is to include source directory
in `~/.rdoc` if it exists;
option `--no-home` may be used to exclude them.

#### Options `--list-doc-dirs`, `--no-list-doc-dirs`

Option `--list-doc-dirs` specifies that a list of the `ri` source directories
is to be displayed;
default is `--no-list-doc-dirs`.

#### Option `--no-standard`

Option `--no-standard` specifies that documents from the standard libraries
are not to be included;
default is to include documents from the standard libraries.

#### Options `--site`, `--no-site`

Option `--site` (the default) specifies that documents from the site libraries
may be included;
option `--no-site` may be used to exclude them.

#### Options `--system`, `--no-system`

Option `--system` (the default) specifies that documents from the system libraries
may be included;
option `--no-system` may be used to exclude them.

### Mode Options

#### Options `--interactive`, `-i`, `--no-interactive`

Option `--interactive` (aliased as `-i`)
specifies that `ri` is to enter interactive mode (ignoring the _name_ if given);
the option is the default when no _name_ is given;
option `--no-interactive` (the default)
specifies that `ri` is not to enter interactive mode,
regardless of whether _name_ is given.

### Information Options

#### Options `--help`, `-h`

Option `--help` (aliased as `-h`) specifies that `ri` is to show
its help text and exit.

#### Options `--version`, `-v`

Option `--version` (aliased as `-v`) specifies that `ri` is to show its version and exit.

### Debugging Options

#### Options `--dump=FILEPATH`, `--no-dump`

Option `--dump=FILEPATH` specifies that `ri` is to dump the content
of the `.ri` file at the given file path;
option`--no-dump` (the default) specifies that `ri` is not to dump content.

The file path may point to any `.ri` file,
but typically would point to one named `cache.ri`:

```sh
$ ri --dump=/usr/share/ri/3.0.0/system/cache.ri | wc -l
14487
$ ri --dump=/usr/share/ri/3.0.0/system/cache.ri | head
{:ancestors=>
  {"Array"=>["Enumerable", "Object"],
   "RubyVM"=>["Object"],
   "RubyVM::AbstractSyntaxTree::Node"=>["Object"],
   "Object"=>["BasicObject", "Kernel"],
   "Integer"=>["Numeric"],
   "Module"=>["Object"],
   "Class"=>["Module"],
   "Complex"=>["Numeric"],
   "NilClass"=>["Object"],
```

#### Options `--profile`, `--no-profile`

Option `--profile` specifies that the program is to be run with the Ruby profiler;
option `no-profile` (the default) specifies that the program is not to be run
with the Ruby profiler.

### Output Options

#### Options `--format=FORMAT`, `-f FORMAT`

Option `--format=FORMAT` (aliased as `-f`) specifies the formatter for the output,
which must be `ansi`, `bs`, `markdown`, or `rdoc`;
the default is `bs` for paged output, `ansi` otherwise.

#### Options `--pager`, `--no-pager`

Option `--pager` (the default) specifies that the output is to be piped
to a pager;
option `--no-pager` specifies that the output is not to be piped.

#### Options `--width=NUMBER`, `-w NUMBER`

Option `--width` (aliased as `-w`) specifies that the lengths of the displayed lines
should be restricted to the given _NUMBER_ of characters;
this is to be accomplished by line-wrapping, not truncation.
The default width is `80`:

```sh
$ ri --width=40 Array | head
= Array < Object

----------------------------------------
= Includes:
Enumerable (from ruby core)

(from ruby core)
----------------------------------------
An Array is an ordered, integer-indexed
collection of objects, called
```


### List Options

#### Options `--list`, `-l`, `--no-list`

Option `--list` (aliased as `-l`) specifies that all class and module names
whose initial characters match the given _name_ are to be displayed:
whose initial characters match the given _name_ are to be displayed:

```sh
$ ri --list Ar | head
ArgumentError
Array
```

If no _name_ is given, all class and module names are displayed.

Option `--no-list` (the default) specifies that a list of class and module names
is not to be displayed.

### Methods Options (for Class or Module)

#### Options `--all`, `-a`, `--no-all`

Option `--all` (aliased as `-a`) specifies that when _name_ identifies a class or module,
the documents for all its methods are included;
option `--no-all` (the default) specifies that the method documents are not to be included:

```shell
$ ri Array | wc -l
390
$ ri --all Array | wc -l
4224
```

### Server Option

#### Option `--server=NUMBER`

Option `--server` specifies that the \RDoc server is to be run on the port
given as _NUMBER_;
the default port is `8214`.

## Generating `ri` Source Files

`ri` by default reads data from directories installed by Ruby and gems.

You can create your own `ri` source files.
This command creates `ri` source files in local directory `my_ri`,
from Ruby source files in local directory `my_sources`:

```sh
$ rdoc --op my_ri --format=ri my_sources
```

Those files may then be considered for any `ri` command
by specifying option `--doc-dir=my_ri`;
see [option \\--doc-dir][20].

[1]: rdoc-ref:RI.md@Static+Mode
[2]: rdoc-ref:RI.md@Interactive+Mode
[3]: rdoc-ref:RI.md@Class+and+Module+Documents
[4]: rdoc-ref:RI.md@Options+--all-2C+-a-2C+--no-all
[5]: rdoc-ref:RI.md@Method+Documents
[6]: rdoc-ref:RI.md@Page+Documents
[7]: rdoc-ref:RI.md@ri+Lists
[8]: rdoc-ref:RI.md@Options+--list-2C+-l-2C+--no-list
[9]: https://docs.ruby-lang.org/en/master/IRB.html
[10]: rdoc-ref:RI.md@Pager
[11]: rdoc-ref:RI.md@Links+in+ri+Output
[12]: rdoc-ref:RI.md@Options+--list-doc-dirs-2C+--no-list-doc-dirs
[13]: rdoc-ref:RI.md@Options+--help-2C+-h
[14]: rdoc-ref:RI.md@Options+--version-2C+-v
[15]: rdoc-ref:RI.md@Options+--dump-3DFILEPATH-2C+--no-dump
[16]: rdoc-ref:RI.md@ri+Information
[17]: rdoc-ref:RI.md@Options
[18]: rdoc-ref:RI.md@ri+at+the+Ready
[19]: rdoc-ref:RI.md@Output+Filters
[20]: rdoc-ref:RI.md@Options+--doc-dir-3DDIRPATH-2C+-d+DIRPATH
