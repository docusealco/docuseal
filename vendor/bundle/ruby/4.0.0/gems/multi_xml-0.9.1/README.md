# MultiXML

[![Tests](https://github.com/sferik/multi_xml/actions/workflows/tests.yml/badge.svg)][tests]
[![Linter](https://github.com/sferik/multi_xml/actions/workflows/linter.yml/badge.svg)][linter]
[![Mutant](https://github.com/sferik/multi_xml/actions/workflows/mutant.yml/badge.svg)][mutant]
[![Typecheck](https://github.com/sferik/multi_xml/actions/workflows/typecheck.yml/badge.svg)][typecheck]
[![Docs](https://github.com/sferik/multi_xml/actions/workflows/docs.yml/badge.svg)][docs]
[![Gem Version](https://badge.fury.io/rb/multi_xml.svg)][gem]

Lots of Ruby libraries parse XML and everyone has their favorite XML parser.
Instead of choosing a single XML parser and forcing users of your library to
be stuck with it, you can use MultiXML instead, which will simply choose the
fastest available XML parser. Here's how to use it:

```ruby
require "multi_xml"

MultiXML.parse("<tag>contents</tag>")                         #=> {"tag" => "contents"}
MultiXML.parse("<tag>contents</tag>", symbolize_names: true)  #=> {tag: "contents"}
```

`MultiXML.parse` returns `{}` for empty and whitespace-only inputs instead of
raising, so a missing or blank payload is observable as an empty hash rather
than an exception. When parsing invalid XML, MultiXML will throw a
`MultiXML::ParseError`.

```ruby
begin
  MultiXML.parse("<open></close>")
rescue MultiXML::ParseError => exception
  exception.xml    #=> "<open></close>"
  exception.cause  #=> Nokogiri::XML::SyntaxError: ...
end
```

### Deprecated in 0.9.0

The module constant, the primary parse entry point, and the
symbolize-keys option were renamed to align MultiXML with MultiJSON
and Ruby stdlib `JSON.parse`. The old names still work in 0.x but
now emit a one-time deprecation warning; they will be removed in 1.0.

| Deprecated                    | Use instead                     |
| ----------------------------- | ------------------------------- |
| `MultiXml` (constant)         | `MultiXML` (all-caps)           |
| `MultiXML.load(xml)`          | `MultiXML.parse(xml)`           |
| `symbolize_keys:` option      | `symbolize_names:` option       |

The `MultiXml` constant (CamelCase) continues to work as a thin
delegator; every method call, constant lookup, and rescue clause
routes through `MultiXML` transparently.

`ParseError` instances expose `xml` and `cause` readers. `xml` contains the
input that caused the problem; `cause` contains the original exception raised
by the underlying parser.

### Writing a custom parser

A custom parser is any class (or module) that responds to two class methods:

```ruby
class MyParser
  def self.parse(io, namespaces: :strip)
    # parse the IO-like object into a Hash, raising ParseError on failure
  end

  def self.parse_error
    MyParser::ParseError
  end
end

MultiXML.parser = MyParser
```

`parse_error` is required: `MultiXML.parse` rescues `MyParser.parse_error`
to wrap parse failures in `MultiXML::ParseError`. The built-in parsers in
`lib/multi_xml/parsers/` are working examples.

MultiXML tries to have intelligent defaulting. If any supported library is
already loaded, MultiXML uses it before attempting to load others. When no
backend is preloaded, MultiXML walks its automatic preference list and uses the first
one that loads successfully:

1. [`ox`][ox]
2. [`libxml-ruby`][libxml-ruby]
3. [`nokogiri`][nokogiri]
4. [`oga`][oga]
5. [`rexml`][rexml]

This is the library's built-in default selection order, not a guarantee that
the list is globally fastest for every workload. Real-world performance depends
on the document shape and the Ruby implementation, and the benchmark suite
below also measures SAX backends that are not part of automatic parser
detection. REXML is a Ruby default gem, so it's always available as a
last-resort fallback on any supported Ruby. If you have a workload where a
different backend is faster, set it explicitly with
`MultiXML.parser = :your_parser`.

## Benchmarking Parsers

This repo includes a benchmark suite that compares every available built-in
backend across multiple XML shapes and sizes instead of relying on a single
synthetic document. The workloads cover:

- shallow and wide XML
- deeply nested XML
- record batches with repeated siblings
- attribute-dense elements
- mixed-content sections
- namespace-heavy feeds
- a large catalog-style document

Run the full benchmark with:

```bash
bundle exec rake benchmark
```

You can also run the script directly for shorter runs or Markdown-friendly
output:

```bash
bundle exec ruby benchmark.rb --quick
bundle exec ruby benchmark.rb --format=markdown
```

The output includes:

- a single best-overall parser based on the equal-weight geometric mean of
  per-scenario relative throughput
- an overall ranking table for every parser
- a scenario matrix showing which parser won each workload
- an exclusions table when a parser crashes or produces mismatched output on a
  valid workload

Allocation efficiency is reported as a secondary metric using allocated Ruby
objects per parse so ties on throughput are easier to interpret.

`PARSER_PREFERENCE` drives auto-detection (see "Configuration" above) and is
ordered fastest-first per the benchmark suite. CI re-runs the benchmark on
each supported runtime and fails if the observed ranking diverges from this
table:

| rank | CRuby/MRI  | JRuby      | TruffleRuby |
| ---- | ---------- | ---------- | ----------- |
| 1    | `ox`       | —          | —           |
| 2    | `libxml`   | —          | `rexml`     |
| 3    | `nokogiri` | `nokogiri` | `libxml`    |
| 4    | `oga`      | —          | `oga`       |
| 5    | `rexml`    | `rexml`    | `nokogiri`  |

A dash means the parser isn't usable on that runtime. `ox` has no JRuby
build and is filtered out of TruffleRuby auto-detection (its SAX callbacks
miscompile under the JIT after warmup); `libxml-ruby` has no JRuby build;
`oga` 3.x crashes on JRuby 10 (its precompiled Java backend was built
against an older JRuby API). TruffleRuby's JIT inverts the FFI-vs-pure-Ruby
tradeoff for the remaining backends, so `rexml` rises to the top and
`nokogiri` falls to last.

## Supported Ruby Versions

This library aims to support and is [tested against](https://github.com/sferik/multi_xml/actions/workflows/tests.yml) the following Ruby
implementations:

- Ruby 3.2
- Ruby 3.3
- Ruby 3.4
- Ruby 4.0
- [JRuby][jruby] 10.0 (targets Ruby 3.4 compatibility)
- [TruffleRuby][truffleruby] 33.0 (native and JVM)

If something doesn't work in one of these implementations, it's a bug.

This library may inadvertently work (or seem to work) on other Ruby
implementations, however support will only be provided for the versions listed
above.

If you would like this library to support another Ruby version, you may
volunteer to be a maintainer. Being a maintainer entails making sure all tests
run and pass on that implementation. When something breaks on your
implementation, you will be responsible for providing patches in a timely
fashion. If critical issues for a particular implementation exist at the time
of a major release, support for that Ruby version may be dropped.

## Versioning

This library aims to adhere to [Semantic Versioning 2.0.0][semver]. Violations
of this scheme should be reported as bugs. Specifically, if a minor or patch
version is released that breaks backward compatibility, that version should be
immediately yanked and/or a new version should be immediately released that
restores compatibility. Breaking changes to the public API will only be
introduced with new major versions. As a result of this policy, you can (and
should) specify a dependency on this gem using the [Pessimistic Version
Constraint][pvc] with two digits of precision. For example:

```ruby
spec.add_dependency "multi_xml", "~> 0.9"
```

## Copyright

Copyright (c) 2010-2026 Erik Berlin. See [LICENSE][license] for details.

[docs]: https://github.com/sferik/multi_xml/actions/workflows/docs.yml
[gem]: https://rubygems.org/gems/multi_xml
[jruby]: http://www.jruby.org/
[libxml-ruby]: https://github.com/xml4r/libxml-ruby
[license]: LICENSE.md
[linter]: https://github.com/sferik/multi_xml/actions/workflows/linter.yml
[mutant]: https://github.com/sferik/multi_xml/actions/workflows/mutant.yml
[nokogiri]: https://nokogiri.org/
[oga]: https://gitlab.com/yorickpeterse/oga
[ox]: https://github.com/ohler55/ox
[pvc]: http://docs.rubygems.org/read/chapter/16#page74
[rexml]: https://github.com/ruby/rexml
[semver]: http://semver.org/
[tests]: https://github.com/sferik/multi_xml/actions/workflows/tests.yml
[truffleruby]: https://www.graalvm.org/ruby/
[typecheck]: https://github.com/sferik/multi_xml/actions/workflows/typecheck.yml
