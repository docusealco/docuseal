lib_dir = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib_dir) unless $LOAD_PATH.include?(lib_dir)

require "optparse"
require "multi_xml"

# Benchmark harness for comparing MultiXML parsers across representative XML workloads.
class MultiXMLBenchmark
  ParserEntry = Struct.new(:name, :module_ref, keyword_init: true)
  PayloadCase = Struct.new(:shape, :bucket, :label, :xml, :bytes, :options, keyword_init: true)
  Measurement = Struct.new(:payload, :parser, :ips, :allocations_per_parse, keyword_init: true)
  RunResults = Struct.new(:parsers, :measurements, :excluded_parsers, keyword_init: true)

  PARSER_NAMES = %i[ox libxml libxml_sax nokogiri nokogiri_sax rexml oga].freeze
  BYTES_PER_MEGABYTE = 1024.0 * 1024.0
  CLOCK = Process::CLOCK_MONOTONIC
  EPSILON = 1e-12
  MAX_ITERATIONS = 1_000_000
  DEFAULTS = {
    warmup: 0.03,
    time: 0.15,
    samples: 5,
    format: :plain,
    validate: true,
    verify_preference: false
  }.freeze

  class << self
    def run(argv = ARGV)
      options = CLI.new.parse(argv)
      parsers = ParserLoader.new.load(options[:parsers])
      raise "No supported parsers are available for benchmarking" if parsers.empty?

      results = Runner.new(parsers:, payloads: PayloadCatalog.new.build, options:).run
      Reporter.new(results:, options:).print
      options[:verify_preference] ? verify_preference(results) : 0
    end

    private

    def verify_preference(results)
      verifier = PreferenceVerifier.new(results)
      verifier.report
      verifier.valid? ? 0 : 1
    end
  end
end

class MultiXMLBenchmark
  # Command-line option parsing for the benchmark script.
  class CLI
    QUICK_OPTIONS = {
      warmup: 0.005,
      time: 0.02,
      samples: 1
    }.freeze
    private_constant :QUICK_OPTIONS

    def parse(argv)
      options = MultiXMLBenchmark::DEFAULTS.dup
      parser(options).parse!(argv)
      validate!(options)
      options
    end

    private

    def parser(options)
      OptionParser.new do |opts|
        opts.banner = "Usage: bundle exec ruby benchmark.rb [options]"
        add_timing_options(opts, options)
        add_format_options(opts, options)
        add_validation_options(opts, options)
        add_quick_option(opts, options)
      end
    end

    def add_timing_options(parser, options)
      parser.on("--warmup SECONDS", Float, "Warmup time budget per benchmark (default: #{MultiXMLBenchmark::DEFAULTS[:warmup]})") do |value|
        options[:warmup] = value
      end
      parser.on("--time SECONDS", Float, "Measurement time budget per sample (default: #{MultiXMLBenchmark::DEFAULTS[:time]})") do |value|
        options[:time] = value
      end
      parser.on("--samples COUNT", Integer, "Samples per benchmark (default: #{MultiXMLBenchmark::DEFAULTS[:samples]})") do |value|
        options[:samples] = value
      end
    end

    def add_format_options(parser, options)
      parser.on("--parsers x,y,z", Array, "Restrict to specific parsers") do |value|
        options[:parsers] = value.map { |name| name.strip.to_sym }
      end
      parser.on("--format FORMAT", %w[plain markdown], "Output format: plain or markdown") do |value|
        options[:format] = value.to_sym
      end
    end

    def add_validation_options(parser, options)
      parser.on("--no-validate", "Skip cross-parser result validation") do
        options[:validate] = false
      end
      parser.on("--verify-preference", "Assert MultiXML::PARSER_PREFERENCE matches benchmark ranking") do
        options[:verify_preference] = true
      end
    end

    def add_quick_option(parser, options)
      parser.on("--quick", "Smoke-test mode with shorter timings") do
        options.merge!(QUICK_OPTIONS)
      end
    end

    def validate!(options)
      validate_warmup!(options[:warmup])
      validate_time!(options[:time])
      validate_samples!(options[:samples])
    end

    def validate_warmup!(value)
      raise OptionParser::InvalidArgument, "--warmup must be >= 0" if value.negative?
    end

    def validate_time!(value)
      raise OptionParser::InvalidArgument, "--time must be > 0" unless value.positive?
    end

    def validate_samples!(value)
      raise OptionParser::InvalidArgument, "--samples must be > 0" unless value.positive?
    end
  end
end

class MultiXMLBenchmark
  # Resolves benchmarkable parsers from the current Ruby environment.
  class ParserLoader
    def load(selected = nil)
      parser_names(selected).filter_map { |name| load_entry(name) }
    end

    private

    def parser_names(selected)
      selected || MultiXMLBenchmark::PARSER_NAMES
    end

    def load_entry(name)
      module_ref = MultiXML.send(:resolve_parser, name)
      MultiXMLBenchmark::ParserEntry.new(name: name, module_ref: module_ref)
    rescue MultiXML::ParserLoadError
      warn "Skipping parser #{name.inspect}: not available"
      nil
    end
  end
end

class MultiXMLBenchmark
  # Builds the benchmark payload matrix across XML shapes and sizes.
  class PayloadCatalog
    CASES = [
      [:shallow_fields, :small, 40],
      [:shallow_fields, :medium, 450],
      [:deep_tree, :medium, 180],
      [:record_batch, :small, 120],
      [:record_batch, :medium, 320],
      [:attribute_dense, :medium, 520],
      [:mixed_content, :medium, 180],
      [:namespace_feed, :medium, 260],
      [:catalog, :large, 1_400]
    ].freeze
    private_constant :CASES

    def build
      CASES.map { |shape, bucket, count| payload_case(shape, bucket, payload_xml(shape, count)) }
    end

    private

    def payload_xml(shape, count)
      case shape
      when :shallow_fields then ShallowPayloadFactory.new.shallow_fields(count)
      when :deep_tree then ShallowPayloadFactory.new.deep_tree(count)
      when :record_batch then RecordPayloadFactory.new.record_batch(count)
      when :attribute_dense then RecordPayloadFactory.new.attribute_dense(count)
      when :mixed_content then MixedPayloadFactory.new.mixed_content(count)
      when :namespace_feed then MixedPayloadFactory.new.namespace_feed(count)
      else CatalogPayloadFactory.new.catalog(count)
      end
    end

    def payload_case(shape, bucket, payload)
      MultiXMLBenchmark::PayloadCase.new(
        shape: shape,
        bucket: bucket,
        label: "#{shape}/#{bucket}",
        bytes: payload.fetch(:xml).bytesize,
        options: payload.fetch(:options).freeze,
        xml: payload.fetch(:xml).freeze
      )
    end

    # Shared helpers for generating XML benchmark payloads.
    class FactoryBase
      private

      def wrap_root(inner)
        "<root>#{inner}</root>"
      end

      def default_options
        {typecast_xml_value: false}
      end

      def timestamp(index)
        Kernel.format("2026-04-%<day>02dT12:%<minute>02d:56Z", day: (index % 28) + 1, minute: index % 60)
      end

      def token(prefix, index, width)
        base = "#{prefix}_#{index.to_s(36)}_abcdefghijklmnopqrstuvwxyz0123456789"
        repeats = (width.to_f / base.length).ceil
        (base * repeats)[0, width]
      end
    end

    # Builds shallow and deep tree payloads.
    class ShallowPayloadFactory < FactoryBase
      def shallow_fields(count)
        xml = wrap_root(
          Array.new(count) do |index|
            "<field#{index}>#{token("node", index, 24)}</field#{index}>"
          end.join
        )

        {xml: xml, options: default_options}
      end

      def deep_tree(depth)
        body = +""
        depth.times do |index|
          body << %(<level#{index} depth="#{index}"><value>#{token("value", index, 24)}</value>)
        end
        depth.times.reverse_each do |index|
          body << %(</level#{index}>)
        end

        {xml: wrap_root(body), options: default_options}
      end
    end

    # Builds record and attribute-heavy payloads.
    class RecordPayloadFactory < FactoryBase
      def record_batch(count)
        xml = wrap_root(Array.new(count) { |index| record(index) }.join)
        {xml: xml, options: default_options}
      end

      def attribute_dense(count)
        xml = wrap_root(Array.new(count) { |index| attributed_node(index) }.join)
        {xml: xml, options: default_options}
      end

      private

      def record(index)
        <<~XML.delete("\n")
          <record id="#{index}">
            #{record_body(index)}
          </record>
        XML
      end

      def record_body(index)
        [
          "<title>#{token("title", index, 40)}</title>",
          "<status>#{(index % 3).zero? ? "active" : "pending"}</status>",
          "<created_at>#{timestamp(index)}</created_at>",
          "<amount>#{Kernel.format("%.2f", ((index * 17) % 10_000) / 10.0)}</amount>",
          "<tags><tag>alpha</tag><tag>beta</tag><tag>#{token("tag", index, 12)}</tag></tags>"
        ].join
      end

      def attributed_node(index)
        attrs = 8.times.map do |slot|
          %(a#{slot}="#{token("attr", index + slot, 14)}")
        end.join(" ")
        %(<node #{attrs}>#{token("node", index, 18)}</node>)
      end
    end

    # Builds mixed-content and namespace-heavy payloads.
    class MixedPayloadFactory < FactoryBase
      def mixed_content(count)
        xml = wrap_root(Array.new(count) { |index| section(index) }.join)
        {xml: xml, options: default_options}
      end

      def namespace_feed(count)
        xml = <<~XML.delete("\n")
          <atom:feed xmlns:atom="http://www.w3.org/2005/Atom"
                     xmlns:gd="http://schemas.google.com/g/2005"
                     xmlns:ex="https://example.test/schema">
            #{Array.new(count) { |index| feed_entry(index) }.join}
          </atom:feed>
        XML

        {xml: xml, options: default_options.merge(namespaces: :preserve)}
      end

      private

      def section(index)
        <<~XML.delete("\n")
          <section id="s#{index}">
            <title>#{token("title", index, 28)}</title>
            <p>This #{token("text", index, 18)} text has <em>inline emphasis #{index}</em> and <strong>strong #{index}</strong>.</p>
            <p>#{token("body", index + 1, 46)} <a href="https://example.test/#{index}">link #{index}</a> #{token("tail", index + 2, 20)}</p>
          </section>
        XML
      end

      def feed_entry(index)
        <<~XML.delete("\n")
          <atom:entry gd:id="item-#{index}" ex:version="#{index}">
            <atom:title>#{token("title", index, 34)}</atom:title>
            <atom:content type="text">#{token("content", index, 58)}</atom:content>
            <gd:rating value="#{(index % 5) + 1}"/>
            <ex:metadata ex:region="us-west-2" ex:trace="trace-#{index}"/>
          </atom:entry>
        XML
      end
    end

    # Builds large catalog-style payloads.
    class CatalogPayloadFactory < FactoryBase
      def catalog(count)
        xml = wrap_root(Array.new(count) { |index| product(index) }.join)
        {xml: xml, options: default_options}
      end

      private

      def product(index)
        <<~XML.delete("\n")
          <product sku="sku-#{index}" region="us" updated="#{timestamp(index)}">
            #{product_body(index)}
          </product>
        XML
      end

      def product_body(index)
        [
          "<name>#{token("name", index, 30)}</name>",
          "<price currency=\"USD\">#{Kernel.format("%.2f", ((index * 13) % 100_000) / 100.0)}</price>",
          "<inventory available=\"#{index % 2}\" warehouse=\"w#{index % 11}\">#{(index * 7) % 400}</inventory>",
          categories(index),
          dimensions(index),
          "<description>#{token("description", index, 120)}</description>"
        ].join
      end

      def categories(index)
        [
          "<categories>",
          "<category>hardware</category>",
          "<category>component</category>",
          "<category>#{token("category", index, 12)}</category>",
          "</categories>"
        ].join
      end

      def dimensions(index)
        "<dimensions><width>#{(index % 100) + 1}</width><height>#{(index % 80) + 1}</height><depth>#{(index % 50) + 1}</depth></dimensions>"
      end
    end
  end
end

class MultiXMLBenchmark
  # Runs the benchmark matrix across parsers and XML payloads.
  class Runner
    # JRuby surfaces parser backend incompatibilities (e.g. Oga's Java
    # backend against newer JRuby) as java.lang.Error subclasses, which
    # are outside Ruby's StandardError hierarchy. Catch the broader Java
    # tree on JRuby so a busted parser is excluded instead of aborting
    # the run. Java::JavaLang::Throwable resolves lazily under JRuby and
    # doesn't respond to defined?, so gate on RUBY_ENGINE.
    RESCUABLE_PARSE_ERRORS = if RUBY_ENGINE == "jruby"
      require "java"
      [StandardError, Java::JavaLang::Throwable].freeze
    else
      [StandardError].freeze
    end
    private_constant :RESCUABLE_PARSE_ERRORS

    def initialize(parsers:, payloads:, options:)
      @parsers = parsers
      @payloads = payloads
      @options = options
      @sampler = MultiXMLBenchmark::Sampler.new(options)
    end

    def run
      eligible_parsers, excluded_parsers = validate_parsers(parsers)
      raise "No parsers passed validation" if eligible_parsers.empty?

      measurements = payloads.each_with_index.flat_map do |payload, index|
        run_payload(payload, eligible_parsers, index)
      end

      MultiXMLBenchmark::RunResults.new(
        excluded_parsers: excluded_parsers,
        measurements: measurements,
        parsers: eligible_parsers
      )
    end

    private

    attr_reader :parsers, :payloads, :options, :sampler

    def validate_parsers(entries)
      return [entries, {}] unless options[:validate]

      expected = expected_outputs(entries)
      excluded = excluded_parsers(entries, expected)
      [entries.reject { |entry| excluded.key?(entry.name) }, excluded]
    end

    def expected_outputs(entries)
      baseline = entries.find { |entry| entry.name == :rexml } || entries.first
      payloads.to_h { |payload| [payload.label, parse_with(baseline, payload)] }
    end

    def excluded_parsers(entries, expected)
      payloads.each_with_object({}) do |payload, excluded|
        entries.each do |entry|
          next if excluded.key?(entry.name)

          reason = validation_failure(entry, payload, expected.fetch(payload.label))
          excluded[entry.name] = "#{payload.label}: #{reason}" if reason
        end
      end
    end

    def validation_failure(entry, payload, expected_output)
      actual = parse_with(entry, payload)
      return nil if actual == expected_output

      "output mismatch"
    rescue *RESCUABLE_PARSE_ERRORS => e
      error_summary(e)
    end

    def run_payload(payload, eligible_parsers, index)
      puts "Benchmarking parse #{payload.label} (#{MultiXMLBenchmark::Formatter.human_bytes(payload.bytes)})"
      rotated_parsers(eligible_parsers, index).map { |entry| measure(entry, payload) }
    end

    def rotated_parsers(entries, index)
      entries.rotate(index % entries.length)
    end

    def measure(entry, payload)
      prime_parser!(entry, payload)
      stats = sampler.sample(entry, payload)
      MultiXMLBenchmark::Measurement.new(
        allocations_per_parse: stats.fetch(:allocations_per_parse),
        ips: stats.fetch(:ips),
        parser: entry.name,
        payload: payload
      )
    end

    def prime_parser!(entry, payload)
      parse_with(entry, payload)
    end

    def parse_with(entry, payload)
      MultiXML.with_parser(entry.module_ref) do
        MultiXML.parse(payload.xml, payload.options)
      end
    end

    def error_summary(error)
      first_line = error.message.to_s.lines.first.to_s.strip
      text = first_line.empty? ? error.class.to_s : "#{error.class}: #{first_line}"
      (text.length > 140) ? "#{text[0, 137]}..." : text
    end
  end
end

class MultiXMLBenchmark
  # Measures throughput for a single parser/payload combination.
  class Sampler
    def initialize(options)
      @options = options
    end

    def sample(entry, payload)
      work = work_for(entry, payload)
      iterations = estimate_iterations(work)
      warmup(work, iterations)
      sample_stats(work, iterations)
    end

    private

    attr_reader :options

    def work_for(entry, payload)
      lambda do
        MultiXML.with_parser(entry.module_ref) do
          MultiXML.parse(payload.xml, payload.options)
        end
      end
    end

    def warmup(work, iterations)
      warmup_iterations = [(iterations * options[:warmup] / options[:time]).round, 1].max
      timed_loop(work, warmup_iterations)
    end

    def sample_stats(work, iterations)
      {
        allocations_per_parse: allocation_median(work, iterations),
        ips: MultiXMLBenchmark::Formatter.median(sample_rates(work, iterations))
      }
    end

    def sample_rates(work, iterations)
      Array.new(options[:samples]) do
        GC.start
        elapsed = with_gc_disabled { timed_loop(work, iterations) }
        iterations.fdiv([elapsed, MultiXMLBenchmark::EPSILON].max)
      end
    end

    def allocation_median(work, iterations)
      allocations = Array.new(options[:samples]) do
        GC.start
        allocation_before = allocation_count
        with_gc_disabled { timed_loop(work, iterations) }
        allocation_delta(allocation_before, iterations)
      end.compact

      allocations.empty? ? nil : MultiXMLBenchmark::Formatter.median(allocations)
    end

    def estimate_iterations(work)
      iterations = 1
      elapsed = with_gc_disabled { timed_loop(work, iterations) }

      while elapsed < 0.001 && iterations < MultiXMLBenchmark::MAX_ITERATIONS
        iterations *= 10
        elapsed = with_gc_disabled { timed_loop(work, iterations) }
      end

      estimated = ((options[:time] / [elapsed, MultiXMLBenchmark::EPSILON].max) * iterations).ceil
      estimated.clamp(1, MultiXMLBenchmark::MAX_ITERATIONS)
    end

    def timed_loop(work, iterations)
      started_at = Process.clock_gettime(MultiXMLBenchmark::CLOCK)
      sink = nil
      iterations.times { sink = work.call }
      raise "Benchmark produced nil" if sink.nil?

      Process.clock_gettime(MultiXMLBenchmark::CLOCK) - started_at
    end

    def allocation_count
      GC.stat.fetch(:total_allocated_objects)
    rescue NoMethodError, KeyError
      nil
    end

    def allocation_delta(before, iterations)
      return nil unless before

      (GC.stat.fetch(:total_allocated_objects) - before).fdiv(iterations)
    rescue NoMethodError, KeyError
      nil
    end

    def with_gc_disabled
      already_disabled = GC.disable
      yield
    ensure
      GC.enable unless already_disabled
    end
  end
end

class MultiXMLBenchmark
  # Prints the benchmark summary and detailed result tables.
  class Reporter
    SUMMARY_HEADERS = ["parser", "overall score", "alloc score", "wins"].freeze
    SUMMARY_ALIGNMENTS = %i[left right right right].freeze
    EXCLUSION_HEADERS = %w[parser reason].freeze
    EXCLUSION_ALIGNMENTS = %i[left left].freeze
    private_constant :SUMMARY_HEADERS, :SUMMARY_ALIGNMENTS, :EXCLUSION_HEADERS, :EXCLUSION_ALIGNMENTS

    def initialize(results:, options:)
      @results = results
      @options = options
    end

    def print
      print_header
      print_summary
      puts
      print_details
      print_exclusions unless results.excluded_parsers.empty?
    end

    private

    attr_reader :results, :options

    def print_header
      puts
      puts "Ruby: #{RUBY_ENGINE} #{RUBY_VERSION} (#{RUBY_PLATFORM})"
      puts "Parsers: #{results.parsers.map(&:name).join(", ")}"
      puts "Method: median ops/s across #{options[:samples]} sample(s); overall score is the geometric"
      puts "mean of per-benchmark throughput normalized to that benchmark's winner."
      puts "Allocation score is a secondary geometric-mean score based on allocated objects per parse."
      puts
    end

    def print_summary
      rows = MultiXMLBenchmark::Summary.new(results.parsers, results.measurements).rows
      puts "Overall winner: #{rows.first[0]}"
      puts MultiXMLBenchmark::TableRenderer.new(format: options[:format]).render(
        SUMMARY_HEADERS,
        rows,
        alignments: SUMMARY_ALIGNMENTS
      )
    end

    def print_details
      detail = MultiXMLBenchmark::Details.new(results.parsers, results.measurements)
      puts MultiXMLBenchmark::TableRenderer.new(format: options[:format]).render(
        detail.headers,
        detail.rows,
        alignments: detail.alignments
      )
    end

    def print_exclusions
      rows = results.excluded_parsers.map { |parser, reason| [parser.to_s, reason] }
      puts
      puts "Excluded parsers"
      puts MultiXMLBenchmark::TableRenderer.new(format: options[:format]).render(
        EXCLUSION_HEADERS,
        rows,
        alignments: EXCLUSION_ALIGNMENTS
      )
    end
  end
end

class MultiXMLBenchmark
  # Asserts MultiXML::PARSER_PREFERENCE matches benchmark throughput ranking.
  #
  # Compares only the parsers that both appear in PARSER_PREFERENCE and were
  # benchmarked on this run, so missing native parsers (e.g. ox on JRuby) are
  # tolerated rather than treated as failures. Adjacent parsers whose
  # observed scores fall within TOLERANCE of each other are treated as
  # tied so noisy benchmark runs that flip close pairs (e.g. oga vs
  # nokogiri on TruffleRuby) don't trigger a failure.
  class PreferenceVerifier
    TOLERANCE = 0.10
    private_constant :TOLERANCE

    def initialize(results)
      @results = results
    end

    def valid?
      violations.empty?
    end

    def report
      if valid?
        report_match
      else
        report_violations
      end
    end

    private

    attr_reader :results

    def preference_order
      @preference_order ||= MultiXML::PARSER_PREFERENCE.map { |_lib, parser| parser }
    end

    def scores
      @scores ||= summary.rows.to_h { |row| [row[0].to_sym, row[1].to_f] }
    end

    def summary
      @summary ||= MultiXMLBenchmark::Summary.new(results.parsers, results.measurements)
    end

    def relevant_parsers
      @relevant_parsers ||= preference_order.select { |parser| scores.key?(parser) }
    end

    def violations
      @violations ||= relevant_parsers.each_cons(2).filter_map do |earlier, later|
        violation_for(earlier, later)
      end
    end

    def violation_for(earlier, later)
      earlier_score = scores.fetch(earlier)
      later_score = scores.fetch(later)
      return nil if later_score <= earlier_score * (1 + TOLERANCE)

      {earlier: earlier, later: later, earlier_score: earlier_score, later_score: later_score}
    end

    def report_match
      puts
      puts "PARSER_PREFERENCE matches benchmark ranking within #{tolerance_pct}% tolerance: #{relevant_parsers.join(", ")}"
    end

    def report_violations
      puts
      puts "PARSER_PREFERENCE does not match benchmark ranking (>#{tolerance_pct}% tolerance):"
      violations.each { |violation| puts "  #{format_violation(violation)}" }
    end

    def format_violation(violation)
      later = violation.fetch(:later)
      earlier = violation.fetch(:earlier)
      later_score = format_score(violation.fetch(:later_score))
      earlier_score = format_score(violation.fetch(:earlier_score))
      excess = (((violation.fetch(:later_score) / violation.fetch(:earlier_score)) - 1) * 100).round
      "#{later} (#{later_score}) outranks #{earlier} (#{earlier_score}) by #{excess}% but is preferenced after it"
    end

    def format_score(value)
      Kernel.format("%.3f", value)
    end

    def tolerance_pct
      (TOLERANCE * 100).to_i
    end
  end
end

class MultiXMLBenchmark
  # Computes overall parser scores and benchmark wins.
  class Summary
    def initialize(parsers, measurements)
      @parsers = parsers
      @measurements = measurements
    end

    def rows
      parsers
        .map { |parser| summary_row(parser) }
        .sort_by { |row| [-row[1].to_f, -allocation_sort_value(row[2]), -row[3].to_i] }
    end

    private

    attr_reader :parsers, :measurements

    def summary_row(parser)
      overall_score = score_for(parser.name)
      allocation_score = allocation_score_for(parser.name)
      [
        parser.name.to_s,
        Kernel.format("%.3f", overall_score),
        allocation_score.nil? ? "n/a" : Kernel.format("%.3f", allocation_score),
        wins.fetch(parser.name, 0).to_s
      ]
    end

    def allocation_sort_value(value)
      return -1.0 if value == "n/a"

      value.to_f
    end

    def score_for(parser_name)
      MultiXMLBenchmark::Formatter.geometric_mean(grouped_ratios.fetch(parser_name))
    end

    def allocation_score_for(parser_name)
      values = grouped_allocation_ratios.fetch(parser_name, [])
      return nil if values.empty?

      MultiXMLBenchmark::Formatter.geometric_mean(values)
    end

    def grouped_ratios
      @grouped_ratios ||= begin
        ratios = Hash.new { |hash, key| hash[key] = [] }
        grouped_measurements.each_value { |entries| append_ratios(ratios, entries) }
        ratios
      end
    end

    def grouped_allocation_ratios
      @grouped_allocation_ratios ||= begin
        ratios = Hash.new { |hash, key| hash[key] = [] }
        grouped_measurements.each_value { |entries| append_allocation_ratios(ratios, entries) }
        ratios
      end
    end

    def wins
      @wins ||= begin
        counts = Hash.new(0)
        grouped_measurements.each_value { |entries| counts[entries.max_by(&:ips).parser] += 1 }
        counts
      end
    end

    def grouped_measurements
      @grouped_measurements ||= measurements.group_by { |measurement| measurement.payload.label }
    end

    def append_ratios(ratios, entries)
      peak = entries.max_by(&:ips).ips
      entries.each do |entry|
        ratios[entry.parser] << normalized_ratio(entry.ips, peak)
      end
    end

    def append_allocation_ratios(ratios, entries)
      alloc_entries = entries.reject { |entry| entry.allocations_per_parse.nil? }
      return if alloc_entries.empty?

      fewest = alloc_entries.min_by(&:allocations_per_parse).allocations_per_parse
      alloc_entries.each do |entry|
        ratios[entry.parser] << normalized_ratio(fewest, entry.allocations_per_parse)
      end
    end

    def normalized_ratio(value, peak)
      value / [peak, MultiXMLBenchmark::EPSILON].max
    end
  end
end

class MultiXMLBenchmark
  # Builds the per-benchmark detail table rows.
  class Details
    def initialize(parsers, measurements)
      @parsers = parsers
      @measurements = measurements
    end

    def headers
      ["benchmark", "bytes", *parsers.map { |parser| "#{parser.name} ops/s" }, "winner"]
    end

    def rows
      payload_labels.map { |label| detail_row(label) }
    end

    def alignments
      [:left, :right, *Array.new(parsers.length, :right), :left]
    end

    private

    attr_reader :parsers, :measurements

    def detail_row(label)
      entries = grouped_measurements.fetch(label)
      [
        label,
        MultiXMLBenchmark::Formatter.human_bytes(entries.first.payload.bytes),
        *parser_rates(index_entries(entries)),
        winner_label(entries)
      ]
    end

    def index_entries(entries)
      entries.each_with_object({}) { |entry, hash| hash[entry.parser] = entry }
    end

    def parser_rates(indexed)
      parsers.map { |parser| MultiXMLBenchmark::Formatter.format_rate(indexed.fetch(parser.name).ips) }
    end

    def winner_label(entries)
      fastest = entries.max_by(&:ips)
      rate = MultiXMLBenchmark::Formatter.format_rate(fastest.ips)
      "#{fastest.parser} (#{rate})"
    end

    def payload_labels
      @payload_labels ||= measurements.map { |measurement| measurement.payload.label }.uniq
    end

    def grouped_measurements
      @grouped_measurements ||= measurements.group_by { |measurement| measurement.payload.label }
    end
  end
end

class MultiXMLBenchmark
  # Renders plain-text and markdown tables for benchmark output.
  class TableRenderer
    def initialize(format:)
      @format = format
    end

    def render(headers, rows, alignments:)
      widths = column_widths(headers, rows)
      return markdown_table(headers, rows, widths) if format == :markdown

      plain_table(headers, rows, widths, alignments)
    end

    private

    attr_reader :format

    def column_widths(headers, rows)
      headers.each_index.map do |index|
        ([headers[index].length] + rows.map { |row| row[index].to_s.length }).max
      end
    end

    def plain_table(headers, rows, widths, alignments)
      [
        format_row(headers, widths, alignments),
        format_row(widths.map { |width| "-" * width }, widths, Array.new(widths.length, :left)),
        *rows.map { |row| format_row(row, widths, alignments) }
      ].join("\n")
    end

    def markdown_table(headers, rows, widths)
      [
        markdown_row(headers, widths),
        markdown_row(widths.map { |width| "-" * width }, widths),
        *rows.map { |row| markdown_row(row, widths) }
      ].join("\n")
    end

    def format_row(row, widths, alignments)
      row.each_with_index.map do |cell, index|
        alignment = alignments[index] || :left
        align_cell(cell.to_s, widths[index], alignment)
      end.join("  ")
    end

    def markdown_row(row, widths)
      cells = row.each_with_index.map { |cell, index| cell.to_s.ljust(widths[index]) }
      "| #{cells.join(" | ")} |"
    end

    def align_cell(text, width, alignment)
      (alignment == :right) ? text.rjust(width) : text.ljust(width)
    end
  end
end

class MultiXMLBenchmark
  # Shared numeric and display formatting helpers for benchmark output.
  class Formatter
    class << self
      def median(values)
        sorted = values.sort
        midpoint = sorted.length / 2
        return sorted[midpoint] if sorted.length.odd?

        (sorted[midpoint - 1] + sorted[midpoint]) / 2.0
      end

      def geometric_mean(values)
        Math.exp(values.sum { |value| Math.log([value, MultiXMLBenchmark::EPSILON].max) } / values.length)
      end

      def format_rate(rate)
        return Kernel.format("%.2fM", rate / 1_000_000.0) if rate >= 1_000_000
        return Kernel.format("%.1fk", rate / 1_000.0) if rate >= 1_000
        return Kernel.format("%.2f", rate) if rate < 10

        Kernel.format("%.0f", rate)
      end

      def human_bytes(bytes)
        return "#{bytes} B" if bytes < 1024
        return Kernel.format("%.1f KB", bytes / 1024.0) if bytes < 1024 * 1024

        Kernel.format("%.2f MB", bytes / MultiXMLBenchmark::BYTES_PER_MEGABYTE)
      end
    end
  end
end

exit(MultiXMLBenchmark.run) if $PROGRAM_NAME == __FILE__
