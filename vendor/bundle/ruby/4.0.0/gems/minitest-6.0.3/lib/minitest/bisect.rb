require_relative "find_minimal_combination"
require_relative "server"
require "shellwords"
require "rbconfig"
require_relative "path_expander" # this is gonna break some shit?

module Minitest; end # :nodoc:

##
# Minitest::Bisect helps you isolate and debug random test failures.

class Minitest::Bisect
  VERSION = "1.8.0" # :nodoc:

  class PathExpander < Minitest::VendoredPathExpander # :nodoc:
    TEST_GLOB = "**/{test_*,*_test,spec_*,*_spec}.rb" # :nodoc:

    attr_accessor :rb_flags

    def initialize args = ARGV # :nodoc:
      super args, TEST_GLOB, "test"
      self.rb_flags = %w[]
    end

    ##
    # Overrides PathExpander#process_flags to filter out ruby flags
    # from minitest flags. Only supports -I<paths>, -d, and -w for
    # ruby.

    def process_flags flags
      flags.reject { |flag| # all hits are truthy, so this works out well
        case flag
        when /^-I(.*)/ then
          rb_flags << flag
        when /^-d/ then
          rb_flags << flag
        when /^-w/ then
          rb_flags << flag
        else
          false
        end
      }
    end
  end

  mtbv = ENV["MTB_VERBOSE"].to_i
  SHH = case # :nodoc:
        when mtbv == 1 then " > /dev/null"
        when mtbv >= 2 then nil
        else " > /dev/null 2>&1"
        end

  # Borrowed from rake
  RUBY = ENV['RUBY'] ||
    File.join(RbConfig::CONFIG['bindir'],
              RbConfig::CONFIG['ruby_install_name'] +
                RbConfig::CONFIG['EXEEXT']).sub(/.*\s.*/m, '"\&"')

  ##
  # True if this run has seen a failure.

  attr_accessor :tainted
  alias :tainted? :tainted

  ##
  # Failures seen in this run. Shape:
  #
  #   {"file.rb"=>{"Class"=>["test_method1", "test_method2"] ...} ...}

  attr_accessor :failures

  ##
  # An array of tests seen so far. NOT cleared by #reset.

  attr_accessor :culprits

  attr_accessor :seen_bad # :nodoc:

  ##
  # Top-level runner. Instantiate and call +run+, handling exceptions.

  def self.run files
    new.run files
  rescue => e
    warn e.message
    warn "Try running with MTB_VERBOSE=2 to verify."
    exit 1
  end

  ##
  # Instantiate a new Bisect.

  def initialize
    self.culprits = []
    self.failures = Hash.new { |h, k| h[k] = Hash.new { |h2, k2| h2[k2] = [] } }
  end

  ##
  # Reset per-bisect-run variables.

  def reset
    self.seen_bad = false
    self.tainted  = false
    failures.clear
    # not clearing culprits on purpose
  end

  ##
  # Instance-level runner. Handles Minitest::Server, argument
  # processing, and invoking +bisect_methods+.

  def run args
    Minitest::Server.run self

    cmd = nil

    mt_flags = args.dup
    expander = Minitest::Bisect::PathExpander.new mt_flags

    files = expander.process.to_a
    rb_flags = expander.rb_flags
    mt_flags += ["--server", $$.to_s]

    cmd = bisect_methods files, rb_flags, mt_flags

    puts "Final reproduction:"
    puts

    system({"MINITEST_SERVER" => "1"}, cmd.sub(/--server \d+/, "", ))
  ensure
    Minitest::Server.stop
  end

  ##
  # Normal: find "what is the minimal combination of tests to run to
  #         make X fail?"
  #
  # Run with: minitest_bisect ... --seed=N
  #
  # 1. Verify the failure running normally with the seed.
  #    2. If no failure, punt.
  #    3. If no passing tests before failure, punt. (No culprits == no debug)
  # 4. Verify the failure doesn't fail in isolation.
  #    5. If it still fails by itself, warn that it might not be an ordering
  #       issue.
  # 6. Cull all tests after the failure, they're not involved.
  # 7. Bisect the culprits + bad until you find a minimal combo that fails.
  # 8. Display minimal combo by running one last time.
  #
  # Inverted: find "what is the minimal combination of tests to run to
  #           make this test pass?"
  #
  # Run with: minitest_bisect ... --seed=N -n="/failing_test_name_regexp/"
  #
  # 1. Verify the failure by running normally w/ the seed and -n=/.../
  #    2. If no failure, punt.
  # 3. Verify the passing case by running everything.
  #    4. If failure, punt. This is not a false positive.
  # 5. Cull all tests after the bad test from #1, they're not involved.
  # 6. Bisect the culprits + bad until you find a minimal combo that passes.
  # 7. Display minimal combo by running one last time.

  def bisect_methods files, rb_flags, mt_flags
    bad_names, mt_flags = mt_flags.partition { |s| s =~ /^(?:-n|--name)/ }
    normal   = bad_names.empty?
    inverted = !normal

    if inverted then
      time_it "reproducing w/ scoped failure (inverted run!)...", build_methods_cmd(build_files_cmd(files, rb_flags, mt_flags + bad_names))
      raise "No failures. Probably not a false positive. Aborting." if failures.empty?
      bad = map_failures
    end

    cmd = build_files_cmd(files, rb_flags, mt_flags)

    msg = normal ? "reproducing..." : "reproducing false positive..."
    time_it msg, build_methods_cmd(cmd)

    if normal then
      raise "Reproduction run passed? Aborting." unless tainted?
      raise "Verification failed. No culprits? Aborting." if culprits.empty? && seen_bad
    else
      raise "Reproduction failed? Not false positive. Aborting." if tainted?
      raise "Verification failed. No culprits? Aborting." if culprits.empty? || seen_bad
    end

    if normal then
      bad = map_failures

      time_it "verifying...", build_methods_cmd(cmd, [], bad)

      new_bad = map_failures

      if bad == new_bad then
        warn "Tests fail by themselves. This may not be an ordering issue."
      end
    end

    idx = culprits.index bad.first
    self.culprits = culprits.take idx+1 if idx # cull tests after bad

    # culprits populated by initial reproduction via minitest/server
    found, count = culprits.find_minimal_combination_and_count do |test|
      prompt = "# of culprit methods: #{test.size}"

      time_it prompt, build_methods_cmd(cmd, test, bad)

      normal == tainted? # either normal and failed, or inverse and passed
    end

    puts
    puts "Minimal methods found in #{count} steps:"
    puts
    puts "Culprit methods: %p" % [found + bad]
    puts
    cmd = build_methods_cmd cmd, found, bad
    puts cmd.sub(/--server \d+/, "")
    puts
    cmd
  end

  def time_it prompt, cmd # :nodoc:
    print prompt
    t0 = Time.now
    system({"MINITEST_SERVER" => "1"}, "#{cmd} #{SHH}")
    puts " in %.2f sec" % (Time.now - t0)
  end

  def map_failures # :nodoc:
    # from: {"file.rb"=>{"Class"=>["test_method1", "test_method2"]}}
    #   to: ["Class#test_method1", "Class#test_method2"]
    failures.values.map { |h|
      h.map { |k,vs| vs.map { |v| "#{k}##{v}" } }
    }.flatten.sort
  end

  def build_files_cmd culprits, rb, mt, cmd:$0 # :nodoc:
    ([cmd] + rb + culprits + mt).shelljoin
  end

  def build_methods_cmd cmd, culprits = [], bad = nil # :nodoc:
    reset

    if bad then
      re = build_re culprits + bad

      cmd += " -n \"#{re}\"" if bad
    end

    if ENV["MTB_VERBOSE"].to_i >= 1 then
      puts
      puts cmd
      puts
    end

    cmd
  end

  def build_re bad # :nodoc:
    re = []

    # bad by class, you perv
    bbc = bad.map { |s| s.split(/#/, 2) }.group_by(&:first)

    bbc.each do |klass, methods|
      methods = methods.map(&:last).flatten.uniq.map { |method|
        re_escape method
      }

      methods = methods.join "|"
      re << /#{re_escape klass}#(?:#{methods})/.to_s[7..-2] # (?-mix:...)
    end

    re = re.join("|").to_s.gsub(/-mix/, "")

    "/^(?:#{re})$/"
  end

  def re_escape str # :nodoc:
    str.gsub(/([`'"!?&\[\]\(\)\{\}\|\+])/, '\\\\\1')
  end

  ############################################################
  # Server Methods:

  def minitest_start # :nodoc:
    self.failures.clear
  end

  def minitest_result file, klass, method, fails, assertions, time # :nodoc:
    fails.reject! { |fail| Minitest::Skip === fail }

    if fails.empty? then
      culprits << "#{klass}##{method}" unless seen_bad # UGH
    else
      self.seen_bad = true
    end

    return if fails.empty?

    self.tainted = true
    self.failures[file][klass] << method
  end
end
