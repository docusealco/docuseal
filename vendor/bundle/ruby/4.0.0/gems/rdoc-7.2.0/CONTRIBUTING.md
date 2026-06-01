# Contributing to RDoc

Thank you for your interest in contributing to RDoc! This document provides guidelines and instructions for contributing.

## Reporting Bugs

If you think you found a bug, open an issue on the [issue tracker](https://github.com/ruby/rdoc/issues) on GitHub.

When reporting a bug:

- Include a sample file that illustrates the problem, or link to the repository/gem associated with the bug
- Include steps to reproduce the issue

## Development Setup

RDoc uses Bundler for development. To get started:

```bash
bundle install
bundle exec rake
```

This will install dependencies and run the tests.

If you're working on CSS or templates, you'll also want Node dependencies for the CSS linter:

```bash
npm install
```

If tests don't pass on the first run, check the [GitHub Actions page](https://github.com/ruby/rdoc/actions) to see if there are any known failures.

**Note:** Generated parser files are committed to the repository. If you delete them (for example via `bundle exec rake clean`) or you change any `.ry`/`.kpeg` parser sources, run `bundle exec rake generate` before running tests.

## Running Tests

```bash
# Run all tests (default task)
bundle exec rake

# Run unit tests only (excludes RubyGems integration)
bundle exec rake normal_test

# Run RubyGems integration tests only
bundle exec rake rubygems_test

# Verify generated parser files are current (CI check)
bundle exec rake verify_generated
```

- **Test Framework:** [`test-unit`](https://github.com/test-unit/test-unit)
- **Test Location:** `test/` directory
- **Test Helper:** `test/lib/helper.rb`

## Linting

### RuboCop (Ruby Code)

```bash
# Check Ruby code style
bundle exec rubocop

# Auto-fix style issues
bundle exec rubocop -A
```

### Herb Linter (ERB/RHTML Templates)

```bash
# Lint ERB template files
npx @herb-tools/linter "**/*.rhtml"

# Lint specific directory
npx @herb-tools/linter "lib/**/*.rhtml"
```

**Template Location:** `lib/rdoc/generator/template/**/*.rhtml`

### Stylelint (CSS Files)

```bash
# Lint CSS files
npm run lint:css

# Auto-fix style issues
npm run lint:css -- --fix
```

## Type annotations

RDoc is currently not a typed codebase. Despite not running a type checker, contributors have been
adding some comment annotations to make the codebase easier to navigate and understand.

These annotations use [Sorbet flavored RBS](https://sorbet.org/docs/rbs-support) annotations,
so that we can tag definitions as abstract and override. For more information on RBS syntax,
see the [documentation](https://github.com/ruby/rbs/blob/master/docs/syntax.md).

## Parser Generation

RDoc uses generated parsers for Markdown and RD formats.

```bash
# Generate all parser files from sources
bundle exec rake generate

# Remove generated parser files
bundle exec rake clean

# Verify generated files are in sync with sources (CI check)
bundle exec rake verify_generated
```

**Source Files** (edit these):

- `lib/rdoc/rd/block_parser.ry` → generates `block_parser.rb` via racc
- `lib/rdoc/rd/inline_parser.ry` → generates `inline_parser.rb` via racc
- `lib/rdoc/markdown.kpeg` → generates `markdown.rb` via kpeg
- `lib/rdoc/markdown/literals.kpeg` → generates `literals.rb` via kpeg

**Important:**

- Generated parser files **should be committed** to the repository
- Do not edit generated `.rb` parser files directly
- After modifying `.ry` or `.kpeg` source files, run `bundle exec rake generate`
- CI runs `rake verify_generated` to ensure generated files are in sync with their sources

## Documentation Generation

```bash
# Generate documentation (creates _site directory)
bundle exec rake rdoc

# Force regenerate documentation
bundle exec rake rerdoc

# Show documentation coverage
bundle exec rake rdoc:coverage
bundle exec rake coverage
```

- **Output Directory:** `_site/` (GitHub Pages compatible)
- **Configuration:** `.rdoc_options` and `.document`

## Themes

RDoc ships with two HTML themes:

- **Aliki** (default) - Modern theme with improved styling and navigation
- **Darkfish** (deprecated) - Classic theme, will be removed in v8.0

New feature development should focus on the Aliki theme. Darkfish will continue to receive bug fixes but no new features.

Theme templates are located at `lib/rdoc/generator/template/<theme>/`.

## Project Structure

```
lib/rdoc/
├── rdoc.rb                    # Main entry point (RDoc::RDoc class)
├── version.rb                 # Version constant
├── task.rb                    # Rake task integration
├── parser/                    # Source code parsers
│   ├── ruby.rb                # Ruby code parser
│   ├── c.rb                   # C extension parser
│   ├── prism_ruby.rb          # Prism-based Ruby parser
│   └── ...
├── generator/                 # Documentation generators
│   ├── aliki.rb               # HTML generator (default theme)
│   ├── darkfish.rb            # HTML generator (deprecated, will be removed in v8.0)
│   ├── markup.rb              # Markup format generator
│   ├── ri.rb                  # RI command generator
│   └── template/              # ERB templates
│       ├── aliki/             # Aliki theme (default)
│       └── darkfish/          # Darkfish theme (deprecated)
├── markup/                    # Markup parsing and formatting
├── code_object/               # AST objects for documented items
├── markdown.kpeg              # Parser source (edit this)
├── markdown.rb                # Generated parser (do not edit)
├── markdown/                  # Markdown parsing
│   ├── literals.kpeg          # Parser source (edit this)
│   └── literals.rb            # Generated parser (do not edit)
├── rd/                        # RD format parsing
│   ├── block_parser.ry        # Parser source (edit this)
│   ├── block_parser.rb        # Generated parser (do not edit)
│   ├── inline_parser.ry       # Parser source (edit this)
│   └── inline_parser.rb       # Generated parser (do not edit)
└── ri/                        # RI (Ruby Info) tool

test/                          # Test files
├── lib/helper.rb              # Test helpers
└── rdoc/                      # Main test directory
```

## Code of Conduct

Please be respectful and constructive in all interactions. We're all here to make RDoc better!
