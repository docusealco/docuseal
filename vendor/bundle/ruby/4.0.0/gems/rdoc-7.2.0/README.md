# RDoc - Ruby Documentation System

- GitHub: [https://github.com/ruby/rdoc](https://github.com/ruby/rdoc)
- Issues: [https://github.com/ruby/rdoc/issues](https://github.com/ruby/rdoc/issues)

## Description

RDoc produces HTML and command-line documentation for Ruby projects.  RDoc includes the `rdoc` and `ri` tools for generating and displaying documentation from the command-line.

## Generating Documentation

Once installed, you can create documentation using the `rdoc` command

```shell
rdoc [options] [names...]
```

For an up-to-date option summary, type

```shell
rdoc --help
```

A typical use might be to generate documentation for a package of Ruby source (such as RDoc itself).

```shell
rdoc
```

This command generates documentation for all the Ruby and C source files in and below the current directory.  These will be stored in a documentation tree starting in the subdirectory `doc`.

You can make this slightly more useful for your readers by having the index page contain the documentation for the primary file.  In our case, we could type

```shell
rdoc --main README.md
```

You'll find information on the various formatting tricks you can use in comment blocks in the documentation this generates.

RDoc uses file extensions to determine how to process each file.  File names ending `.rb` and `.rbw` are assumed to be Ruby source.  Files ending `.c` are parsed as C files.  All other files are assumed to contain just Markup-style markup (with or without leading `#` comment markers).  If directory names are passed to RDoc, they are scanned recursively for C and Ruby source files only.

To generate documentation using `rake` see [RDoc::Task](https://ruby.github.io/rdoc/RDoc/Task.html).

To generate documentation programmatically:

```rb
require 'rdoc/rdoc'

options = RDoc::Options.new
options.files = ['a.rb', 'b.rb']
options.setup_generator 'aliki'
# see RDoc::Options

rdoc = RDoc::RDoc.new
rdoc.document options
# see RDoc::RDoc
```

You can specify the target files for document generation with `.document` file in the project root directory. `.document` file contains a list of file and directory names including comment lines starting with `#`. See [https://github.com/ruby/rdoc/blob/master/.document](https://github.com/ruby/rdoc/blob/master/.document) as an example.

## Writing Documentation

To write documentation for RDoc, place a comment above the class, module, method, constant, or attribute you want documented:

```rb
##
# This class represents an arbitrary shape by a series of points.
class Shape
  ##
  # Creates a new shape described by a +polyline+.
  #
  # If the +polyline+ does not end at the same point it started at the
  # first pointed is copied and placed at the end of the line.
  #
  # An ArgumentError is raised if the line crosses itself, but shapes may
  # be concave.
  def initialize polyline
    # ...
  end
end
```

### Markup Formats

RDoc supports multiple markup formats:

| Format | File Extensions | Default For |
|--------|-----------------|-------------|
| [RDoc](doc/markup_reference/rdoc.rdoc) | `.rdoc` | `.rb`, `.c` files |
| [Markdown](doc/markup_reference/markdown.md) | `.md` | None |
| RD | `.rd` | None |
| TomDoc | N/A | None |

**RDoc markup** is currently the default format for Ruby and C files. However, we plan to retire it in favor of Markdown in the future.

**Markdown** support is actively being improved. Once it reaches feature parity with RDoc markup, it will become the default format.

For standalone documentation files, we recommend writing `.md` files instead of `.rdoc` files.

**RD** and **TomDoc** are legacy formats. We highly discourage their use in new projects.

### Specifying Markup Format

**Per-file:** Add a `:markup:` directive at the top of a Ruby file:

```ruby
# :markup: markdown

# This class uses **Markdown** for documentation.
class MyClass
end
```

**Per-project:** Create a `.rdoc_options` file in your project root:

```yaml
markup: markdown
```

**Command line:**

```bash
rdoc --markup markdown
```

### Feature Differences

| Feature | RDoc Markup | Markdown |
|---------|-------------|----------|
| Headings | `= Heading` | `# Heading` |
| Bold | `*word*` | `**word**` |
| Italic | `_word_` | `*word*` |
| Monospace | `+word+` | `` `word` `` |
| Links | `{text}[url]` | `[text](url)` |
| Code blocks | Indent 2 spaces | Fenced with ``` |
| Cross-references | Automatic | Automatic |
| Directives (`:nodoc:`, etc.) | Supported | Supported |
| Tables | Not supported | Supported |
| Strikethrough | `<del>text</del>` | `~~text~~` |
| Footnotes | Not supported | Supported |

For complete syntax documentation, see:

- [RDoc Markup Reference](doc/markup_reference/rdoc.rdoc)
- [Markdown Reference](doc/markup_reference/markdown.md)

### Directives

Comments can contain directives that tell RDoc information that it cannot otherwise discover through parsing. See RDoc::Markup@Directives to control what is or is not documented, to define method arguments or to break up methods in a class by topic. See RDoc::Parser::Ruby for directives used to teach RDoc about metaprogrammed methods.

See RDoc::Parser::C for documenting C extensions with RDoc.

### Documentation Coverage

To determine how well your project is documented run `rdoc -C lib` to get a documentation coverage report. `rdoc -C1 lib` includes parameter names in the documentation coverage report.

## Theme Options

RDoc ships with two built-in themes:

- **Aliki** (default) - A modern, clean theme with improved navigation and search
- **Darkfish** (deprecated) - The classic theme, will be removed in v8.0

To use the Darkfish theme instead of the default Aliki theme:

```shell
rdoc --format darkfish
```

Or in your `.rdoc_options` file:

```yaml
generator_name: darkfish
```

There are also a few community-maintained themes for RDoc:

- [rorvswild-theme-rdoc](https://github.com/BaseSecrete/rorvswild-theme-rdoc)
- [hanna](https://github.com/jeremyevans/hanna) (a fork maintained by [Jeremy Evans](https://github.com/jeremyevans))

Please follow the theme's README for usage instructions.

## Bugs

See [CONTRIBUTING.md](CONTRIBUTING.md) for information on filing a bug report.  It's OK to file a bug report for anything you're having a problem with.  If you can't figure out how to make RDoc produce the output you like that is probably a documentation bug.

## License

RDoc is Copyright (c) 2001-2003 Dave Thomas, The Pragmatic Programmers. Portions (c) 2007-2011 Eric Hodel.  Portions copyright others, see individual files and LEGAL.rdoc for details.

RDoc is free software, and may be redistributed under the terms specified in LICENSE.rdoc.

## Warranty

This software is provided "as is" and without any express or implied warranties, including, without limitation, the implied warranties of merchantability and fitness for a particular purpose.
