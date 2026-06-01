0.9.1
-----
* Fix `MultiXml.method(:load)` resolving to `Kernel#load`. The legacy `MultiXml` constant forwarded calls to `MultiXML` via `method_missing`, but `Module#method` doesn't consult `method_missing`, so `MultiXml.method(:load)` resolved to the inherited `Kernel#load` and crashed with `LoadError` when invoked. Replaces `method_missing` with explicit singleton-method forwarders for every public method on `MultiXML`, mirroring the [analogous fix in MultiJSON](https://github.com/sferik/multi_json/issues/66).

0.9.0
-----
* Add `MultiXML.with_parser` for fiber-local scoped parser overrides, matching `MultiJSON.with_adapter`. The override lives in `Fiber[:multi_xml_parser]`, so concurrent fibers and threads each see their own parser without racing on a shared module variable; nested calls save and restore the previous value.
* Add `MultiXML.parse_options` / `MultiXML.parse_options=` for process-wide default options, matching `MultiJSON.parse_options`. Accepts a `Hash` or a callable (`Proc`/`lambda`); a callable receives the call-site hash as its sole positional argument so defaults can be computed per-call. Defaults merge between `DEFAULT_OPTIONS` and call-site overrides.
* Introduce `MultiXML::Parser` base module — built-in parsers declare their backend exception class via a `ParseError` constant, matching the `MultiJSON::Adapter` convention. Custom parsers can either extend `MultiXML::Parser` and define `ParseError` or keep defining a `.parse_error` method directly; both styles are accepted.
* Add `MultiXML::ParserLoadError`, raised when the parser spec is invalid, requiring the parser file raises `LoadError`, or the resolved parser doesn't satisfy the contract (must respond to `.parse` and define either a `ParseError` constant or a `.parse_error` method). Inherits from `ArgumentError` and carries the original exception's class name in its message, matching `MultiJSON::AdapterError`.
* Rename `MultiXml` constant to `MultiXML` (all caps), matching the style of `MultiJSON`. The old `MultiXml` constant continues to work but emits a one-time deprecation warning on first use and will be removed in v1.0.
* Add `MultiXML.load` as a deprecated alias for `MultiXML.parse`, matching the style of `MultiJSON.load` → `MultiJSON.parse`. Will be removed in v1.0.
* Rename the `:symbolize_keys` option to `:symbolize_names`, matching Ruby stdlib's `JSON.parse` and MultiJSON. The old option continues to work but emits a one-time deprecation warning; it will be removed in v1.0.
* [Add `:namespaces` option to `MultiXML.parse` for consistent namespace handling across parsers](https://github.com/sferik/multi_xml/issues/44) — two modes produce byte-identical output on every backend:
  * `:strip` (default) — drop xmlns declarations and prefixes; keeps today's libxml/nokogiri output so most users see no change
  * `:preserve` — keep source prefixes (e.g. `"atom:rel"`) and surface `xmlns` / `xmlns:*` declarations as attributes
* Fix REXML keeping attribute prefixes (`"gd:etag"`) while other backends stripped them ([#31](https://github.com/sferik/multi_xml/issues/31))
* Fix Ox prepending namespace prefixes to element names (`"aws:Item"`) when other backends didn't ([#30](https://github.com/sferik/multi_xml/issues/30))
* Handle namespaced attribute name collisions consistently across backends. When attributes with different prefixes strip to the same local name (e.g. `foo:id` and `bar:id` both becoming `id`), values are collected in an array in document order, with attribute values ahead of any colliding child elements. The libxml SAX parser falls back to its DOM backend in this case since the SAX callback drops attribute prefixes.
* Fix Ox mixed-content text aggregation in the SAX parser
* Raise `ArgumentError` on an unknown `:namespaces` mode
* `undasherize_keys` now runs only in `:strip` mode so prefixed keys aren't rewritten under `:preserve`
* Reorder `PARSER_PREFERENCE` so `oga` is tried before `rexml`, matching the throughput ranking in the bundled benchmark suite. Affects auto-detection only when neither `ox`, `libxml-ruby`, nor `nokogiri` is available; explicitly selecting a parser is unchanged.
* Use a TruffleRuby-specific `PARSER_PREFERENCE` ordering (`rexml`, `libxml`, `oga`, `nokogiri`) since TruffleRuby's JIT favors pure-Ruby parsers and penalizes FFI-bound ones. On other engines the default ordering is unchanged.
* Add a parser benchmark suite (`rake benchmark`) and document per-engine throughput rankings in the README. CI verifies that `PARSER_PREFERENCE` matches the benchmark ranking on MRI, JRuby, and TruffleRuby.
* Restore JRuby support (dropped in 0.8.0) and add TruffleRuby (native + JVM) to the CI matrix, matching the test coverage of MultiJSON. TruffleRuby is excluded from Windows runners since the `setup-ruby` action doesn't support it there.
* Add Ruby 4.0 to the CI matrix
* Support libxml-ruby 6.0.0 by switching from `require "libxml"` (removed in 6.0) to `require "libxml-ruby"`, which is present in both 5.x and 6.x
* Drop redundant `::Psych::SyntaxError` declaration from the RBS signature to fix a "Different superclasses are specified" type-checking error under rbs v4

0.8.1
-----
* [Fix array unwrapping when elements contain nil](https://github.com/sferik/multi_xml/commit/09a875d832c45e2b567889398f45361ec9e36685)

0.8.0
-----
* [Add per-parse :parser option to MultiXml.parse](https://github.com/sferik/multi_xml/commit/eb0c1ccadd9026980ba8b6dd0128d6862dc361c4)
* [Add SAX parsers for Nokogiri and LibXML](https://github.com/sferik/multi_xml/commit/5d67fe6cae3c1ef2c306f1e83fc91b9accfcb724)
* [Fix inconsistent whitespace handling across parsers](https://github.com/sferik/multi_xml/commit/55aa23f1c401e66984ad1c7d753c1b4258bf0dfd)
* [Make parsing errors inspectable with cause and xml accessors](https://github.com/sferik/multi_xml/commit/f676f1b657f3352a80ac171d9b839e41ad52a14d)
* [Drop support for JRuby](https://github.com/sferik/multi_xml/commit/27895ca3918c681ad7ddaa57c5cae7b8340bd601)

0.7.2
-----
* [Drop support for Ruby 3.1](https://github.com/sferik/multi_xml/commit/fab6288edd36c58a2b13e0206d8bed305fcb4a4b)

0.7.1
-----
* [Relax required Ruby version constraint to allow installation on Debian stable](https://github.com/sferik/multi_xml/commit/7d18711466a15e158dc71344ca6f6e18838ecc8d)

0.7.0
-----
* [Add support for Ruby 3.3](https://github.com/sferik/multi_xml/pull/67)
* [Drop support for Ruby 3.0](https://github.com/sferik/multi_xml/commit/eec72c56307fede3a93f1a61553587cb278b0c8a) [and](https://github.com/sferik/multi_xml/commit/6a6dec80a36c30774a5525b45f71d346fb561e69) [earlier](https://github.com/sferik/multi_xml/commit/e7dad37a0a0be8383a26ffe515c575b5b4d04588)
* [Don't mutate strings](https://github.com/sferik/multi_xml/commit/71be3fff4afb0277a7e1c47c5f1f4b6106a8eb45)

0.6.0
-----
* [Duplexed Streams](https://github.com/sferik/multi_xml/pull/45)
* [Support for Oga](https://github.com/sferik/multi_xml/pull/47)
* [Integer unification for Ruby 2.4](https://github.com/sferik/multi_xml/pull/54)

0.5.5
-----
* [Fix symbolize_keys function](https://github.com/sferik/multi_xml/commit/a4cae3aeb690999287cd30206399abaa5ce1ae81)
* [Fix Nokogiri parser for the same attr and inner element name](https://github.com/sferik/multi_xml/commit/a28ed86e2d7826b2edeed98552736b4c7ca52726)

0.5.4
-----
* [Add option to not cast parsed values](https://github.com/sferik/multi_xml/commit/44fc05fbcfd60cc8b555b75212471fab29fa8cd0)
* [Use message instead of to_s](https://github.com/sferik/multi_xml/commit/b06f0114434ffe1957dd7bc2712cb5b76c1b45fe)

0.5.3
-----
* [Add cryptographic signature](https://github.com/sferik/multi_xml/commit/f39f0c74308090737816c622dbb7d7aa28c646c0)

0.5.2
-----
* [Remove ability to parse symbols and YAML](https://github.com/sferik/multi_xml/pull/34)

0.5.1
-----
* [Revert "Reset @@parser in between specs"](https://github.com/sferik/multi_xml/issues/28)

0.5.0
-----
* [Reset @@parser in between specs](https://github.com/sferik/multi_xml/commit/b562bed265918b43ac1c4c638ae3a7ffe95ecd83)
* [Add attributes being passed through on content nodes](https://github.com/sferik/multi_xml/commit/631a8bb3c2253db0024f77f47c16d5a53b8128fd)

0.4.4
-----
* [Fix regression in MultiXml.parse](https://github.com/sferik/multi_xml/commit/45ae597d9a35cbd89cc7f5518c85bac30199fc06)

0.4.3
-----
* [Make parser a class variable](https://github.com/sferik/multi_xml/commit/6804ffc8680ed6466c66f2472f5e016c412c2c24)
* [Add TYPE_NAMES constant](https://github.com/sferik/multi_xml/commit/72a21f2e86c8e3ac9689cee5f3a62102cfb98028)

0.4.2
-----
* [Fix bug in dealing with xml element attributes for both REXML and Ox](https://github.com/sferik/multi_xml/commit/ba3c1ac427ff0268abaf8186fb4bd81100c99559)
* [Make Ox the preferred XML parser](https://github.com/sferik/multi_xml/commit/0a718d740c30fba426f300a929cda9ee8250d238)

0.4.1
-----
* [Use the SAX like parser with Ox](https://github.com/sferik/multi_xml/commit/d289d42817a32e48483c00d5361c76fbea62a166)

0.4.0
-----
* [Add support for Ox](https://github.com/sferik/multi_xml/pull/14)

0.3.0
-----
* [Remove core class monkeypatches](https://github.com/sferik/multi_xml/commit/f7cc3ce4d2924c0e0adc6935d1fba5ec79282938)
* [Sort out some class / singleton class issues](https://github.com/sferik/multi_xml/commit/a5dac06bcf658facaaf7afa295f1291c7be15a44)
* [Have parsers refer to toplevel CONTENT_ROOT instead of defining it](https://github.com/sferik/multi_xml/commit/94e6fa49e69b2a2467a0e6d3558f7d9815cae47e)
* [Move redundant input sanitizing to top-level](https://github.com/sferik/multi_xml/commit/4874148214dbbd2e5a4b877734e2519af42d6132)
* [Refactor libxml and nokogiri parsers to inherit from a common ancestor](https://github.com/sferik/multi_xml/commit/e0fdffcbfe641b6aaa3952ffa0570a893de325c2)

0.2.2
-----
* [Respect the global load path](https://github.com/sferik/multi_xml/commit/68eb3011b37f0e0222bb842abd2a78e1285a97c1)

0.2.1
-----
* [Add BlueCloth gem as development dependency for Markdown formatting](https://github.com/sferik/multi_xml/commit/18195cd1789176709f68f0d7f8df7fc944fe4d24)
* [Replace BlueCloth with Maruku for JRuby compatibility](https://github.com/sferik/multi_xml/commit/bad5516a5ec5e7ef7fc5a35c411721522357fa19)

0.2.0
-----
* [Do not automatically load all library files](https://github.com/sferik/multi_xml/commit/dbd0447e062e8930118573c5453150e9371e5955)

0.1.4
-----
* [Preserve backtrace when catching/throwing exceptions](https://github.com/sferik/multi_xml/commit/7475ee90201c2701fddd524082832d16ca62552d)

0.1.3
-----
* [Common error handling for all parsers](https://github.com/sferik/multi_xml/commit/5357c28eddc14e921fd1be1f445db602a8dddaf2)

0.1.2
-----
* [Make wrap an Array class method](https://github.com/sferik/multi_xml/commit/28307b69bd1d9460353c861466e425c2afadcf56)

0.1.1
-----
* [Fix parsing for strings that contain newlines](https://github.com/sferik/multi_xml/commit/68087a4ce50b5d63cfa60d6f1fcbc2f6d689e43f)

0.1.0
-----
* [Add support for LibXML and Nokogiri](https://github.com/sferik/multi_xml/commit/856bb17fce66601e0b3d3eb3b64dbeb25aed3bca)

0.0.1
-----
* [REXML support](https://github.com/sferik/multi_xml/commit/2a848384a7b90fb3e26b5a8d4dc3fa3e3f2db5fc)
