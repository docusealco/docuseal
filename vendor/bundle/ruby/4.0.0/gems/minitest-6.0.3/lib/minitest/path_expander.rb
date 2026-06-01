require "prism"
require "pathname" # for ruby 3

module Minitest; end # :nodoc:

##
# PathExpander helps pre-process command-line arguments expanding
# directories into their constituent files. It further helps by
# providing additional mechanisms to make specifying subsets easier
# with path subtraction and allowing for command-line arguments to be
# saved in a file.
#
# NOTE: this is NOT an options processor. It is a path processor
# (basically everything else besides options). It does provide a
# mechanism for pre-filtering cmdline options, but not with the intent
# of actually processing them in PathExpander. Use OptionParser to
# deal with options either before or after passing ARGV through
# PathExpander.

class Minitest::VendoredPathExpander
  # extracted version = "2.0.0"

  ##
  # The args array to process.

  attr_accessor :args

  ##
  # The glob used to expand dirs to files.

  attr_accessor :glob

  ##
  # The path to scan if no paths are found in the initial scan.

  attr_accessor :path

  ##
  # Create a new path expander that operates on args and expands via
  # glob as necessary. Takes an optional +path+ arg to fall back on if
  # no paths are found on the initial scan (see #process_args).

  def initialize args, glob, path = "."
    self.args = args
    self.glob = glob
    self.path = path
  end

  ##
  # Takes an array of paths and returns an array of paths where all
  # directories are expanded to all files found via the glob provided
  # to PathExpander.
  #
  # Paths are normalized to not have a leading "./".

  def expand_dirs_to_files *dirs
    dirs.flatten.map { |p|
      if File.directory? p then
        Dir[File.join(p, glob)].find_all { |f| File.file? f }
      else
        p
      end
    }.flatten.sort.map { |s| _normalize s }
  end

  def _normalize(f) = Pathname.new(f).cleanpath.to_s # :nodoc:

  ##
  # Process a file into more arguments. Override this to add
  # additional capabilities.

  def process_file path
    File.readlines(path).map(&:chomp)
  end

  ##
  # Enumerate over args passed to PathExpander and return a list of
  # files and flags to process. Arguments are processed as:
  #
  # @file_of_args :: Read the file and append to args.
  # -file_path    :: Subtract path from file to be processed.
  # -dir_path     :: Expand and subtract paths from files to be processed.
  # -not_a_path   :: Add to flags to be processed.
  # dir_path      :: Expand and add to files to be processed.
  # file_path     :: Add to files to be processed.
  # -             :: Add "-" (stdin) to files to be processed.
  #
  # See expand_dirs_to_files for details on how expansion occurs.
  #
  # Subtraction happens last, regardless of argument ordering.
  #
  # If no files are found (which is not the same as having an empty
  # file list after subtraction), then fall back to expanding on the
  # default #path given to initialize.

  def process_args
    pos_files = []
    neg_files = []
    flags     = []
    clean     = true

    root_dir = File.expand_path "/" # needed for windows paths

    args.each do |arg|
      case arg
      when /^@(.*)/ then # push back on, so they can have dirs/-/@ as well
        clean = false
        args.concat process_file $1
      when "-" then
        pos_files << arg
      when /^-(.*)/ then
        if File.exist? $1 then
          clean = false
          neg_files += expand_dirs_to_files($1)
        else
          flags << arg
        end
      else
        root_path = File.expand_path(arg) == root_dir # eg: -n /./
        if File.exist? arg and not root_path then
          clean = false
          pos_files += expand_dirs_to_files(arg)
        else
          flags << arg
        end
      end
    end

    files = pos_files - neg_files
    files += expand_dirs_to_files(self.path) if files.empty? && clean

    [files, flags]
  end

  ##
  # Process over flags and treat any special ones here. Returns an
  # array of the flags you haven't processed.
  #
  # This version does nothing. Subclass and override for
  # customization.

  def process_flags flags
    flags
  end

  ##
  # Top-level method processes args. If no block is given, immediately
  # returns with an Enumerator for further chaining.
  #
  # Otherwise, it calls +pre_process+, +process_args+ and
  # +process_flags+, enumerates over the files, and then calls
  # +post_process+, returning self for any further chaining.
  #
  # Most of the time, you're going to provide a block to process files
  # and do nothing more with the result. Eg:
  #
  #     PathExpander.new(ARGV).process do |f|
  #       puts "./#{f}"
  #     end
  #
  # or:
  #
  #     PathExpander.new(ARGV).process # => Enumerator

  def process(&b)
    return enum_for(:process) unless block_given?

    pre_process

    files, flags = process_args

    args.replace process_flags flags

    files.uniq.each(&b)

    post_process

    self
  end

  ##
  # Hook to run before process

  def pre_process = nil

  ##
  # Hook to run after process

  def post_process = nil

  ##
  # A file filter mechanism similar to, but not as extensive as,
  # .gitignore files:
  #
  # + If a pattern does not contain a slash, it is treated as a shell glob.
  # + If a pattern ends in a slash, it matches on directories (and contents).
  # + Otherwise, it matches on relative paths.
  #
  # File.fnmatch is used throughout, so glob patterns work for all 3 types.
  #
  # Takes a list of +files+ and either an io or path of +ignore+ data
  # and returns a list of files left after filtering.

  def filter_files files, ignore
    ignore_paths = if ignore.respond_to? :read then
                     ignore.read
                   elsif File.exist? ignore then
                     File.read ignore
                   end

    if ignore_paths then
      nonglobs, globs = ignore_paths.split("\n").partition { |p| p.include? "/" }
      dirs, ifiles    = nonglobs.partition { |p| p.end_with? "/" }
      dirs            = dirs.map { |s| s.chomp "/" }

      dirs.map!   { |i| File.expand_path i }
      globs.map!  { |i| File.expand_path i }
      ifiles.map! { |i| File.expand_path i }

      only_paths = File::FNM_PATHNAME
      files = files.reject { |f|
        f = File.expand_path(f)
        dirs.any?     { |i| File.fnmatch?(i, File.dirname(f), only_paths) } ||
          globs.any?  { |i| File.fnmatch?(i, f) } ||
          ifiles.any? { |i| File.fnmatch?(i, f, only_paths) }
      }
    end

    files
  end
end # VendoredPathExpander

##
# Minitest's PathExpander to find and filter tests.

class Minitest::PathExpander < Minitest::VendoredPathExpander
  attr_accessor :by_line # :nodoc:

  TEST_GLOB = "**/{test_*,*_test,spec_*,*_spec}.rb" # :nodoc:

  def initialize args = ARGV # :nodoc:
    super args, TEST_GLOB, "test"
    self.by_line = {}
  end

  def process_args # :nodoc:
    args.reject! { |arg|                # this is a good use of overriding
      case arg
      when /^(.*):([\d,-]+)$/ then
        f, ls = $1, $2
        ls = ls
          .split(/,/)
          .map { |l|
            case l
            when /^\d+$/ then
              l.to_i
            when /^(\d+)-(\d+)$/ then
              $1.to_i..$2.to_i
            else
              raise "unhandled argument format: %p" % [l]
            end
          }
        next unless File.exist? f
        f = _normalize f
        args << f                       # push path on lest it run whole dir
        by_line[f] = ls                 # implies rejection
      end
    }

    super
  end

  ##
  # Overrides PathExpander#process_flags to filter out ruby flags
  # from minitest flags. Only supports -I<paths>, -d, and -w for
  # ruby.

  def process_flags flags
    flags.reject { |flag| # all hits are truthy, so this works out well
      case flag
      when /^-I(.*)/ then
        $LOAD_PATH.prepend(*$1.split(/:/))
      when /^-d/ then
        $DEBUG = true
      when /^-w/ then
        $VERBOSE = true
      else
        false
      end
    }
  end

  ##
  # Add additional arguments to args to handle path:line argument filtering

  def post_process
    return if by_line.empty?

    tests = tests_by_class

    exit! 1 if handle_missing_tests? tests

    test_res = tests_to_regexp tests
    self.args << "-n" << "/#{test_res.join "|"}/"
  end

  ##
  # Find and return all known tests as a hash of klass => [TM...]
  # pairs.

  def all_tests
    Minitest.seed = 42 # minor hack to deal with runnable_methods shuffling
    Minitest::Runnable.runnables
      .to_h { |k|
        ms = k.runnable_methods
          .sort
          .map { |m| TM.new k, m.to_sym }
          .sort_by { |t| [t.path, t.line_s] }
        [k, ms]
      }
      .reject { |k, v| v.empty? }
  end

  ##
  # Returns a hash mapping Minitest runnable classes to TMs

  def tests_by_class
    all_tests
      .transform_values { |ms|
        ms.select { |m|
          bl = by_line[m.path]
          not bl or bl.any? { |l| m.include? l }
        }
      }
      .reject { |k, v| v.empty? }
  end

  ##
  # Converts +tests+ to an array of "klass#(methods+)" regexps to be
  # used for test selection.

  def tests_to_regexp tests
    tests                                         # { k1 => [Test(a), ...}
      .transform_values { |tms| tms.map(&:name) } # { k1 => %w[a, b], ...}
      .map { |k, ns|                              # [ "k1#(?:a|b)", "k2#c", ...]
        if ns.size > 1 then
          ns.map! { |n| Regexp.escape n }
          "%s#\(?:%s\)" % [Regexp.escape(k.name), ns.join("|")]
        else
          "%s#%s" % [Regexp.escape(k.name), ns.first]
        end
      }
  end

  ##
  # Handle the case where a line number doesn't match any known tests.
  # Returns true to signal that running should stop.

  def handle_missing_tests? tests
    _tests = tests.values.flatten
    not_found = by_line
      .flat_map { |f, ls| ls.map { |l| [f, l] } }
      .reject { |f, l|
        _tests.any? { |t| t.path == f and t.include? l }
      }

    unless not_found.empty? then
      by_path = all_tests.values.flatten.group_by(&:path)

      puts
      puts "ERROR: test(s) not found at:"
      not_found.each do |f, l|
        puts "  %s:%s" % [f, l]
        puts
        puts "Did you mean?"
        puts
        l = l.begin if l.is_a? Range
        by_path[f] and
          by_path[f]
          .sort_by { |m| (m.line_s - l).abs }
          .first(2)
          .each do |m|
            puts "  %-30s (dist=%+d) (%s)" % [m, m.line_s - l, m.name]
          end
        puts
      end
      $stdout.flush
      $stderr.flush
      true
    end
  end

  ##
  # Simple TestMethod (abbr TM) Data object.

  TM = Data.define :klass, :name, :path, :lines do
    def initialize klass:, name:
      method = klass.instance_method name
      path, line_s = method.source_location

      path = path.delete_prefix "#{Dir.pwd}/"

      line_e = line_s + TM.source_for(method).lines.size - 1

      lines = line_s..line_e

      super klass:, name:, path:, lines:
    end

    def self.source_for method
      path, line = method.source_location
      file = cache[path] ||= File.readlines(path)

      ruby = +""

      file[line-1..].each do |l|
        ruby << l
        return ruby if Prism.parse_success? ruby
      end

      nil
    end

    def self.cache = @cache ||= {}

    def include?(o) = o.is_a?(Integer) ? lines.include?(o) : lines.overlap?(o)

    def to_s = "%s:%d-%d" % [path, lines.begin, lines.end]

    def line_s = lines.begin
  end
end
