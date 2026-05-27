require "semantic_range/version"
require "semantic_range/pre_release"
require "semantic_range/range"
require "semantic_range/comparator"

module SemanticRange
  BUILDIDENTIFIER = /[0-9A-Za-z-]+/
  BUILD = /(?:\+(#{BUILDIDENTIFIER.source}(?:\.#{BUILDIDENTIFIER.source})*))/
  NUMERICIDENTIFIER = /0|[1-9]\d*/
  NUMERICIDENTIFIERLOOSE = /[0-9]+/
  NONNUMERICIDENTIFIER = /\d*[a-zA-Z-][a-zA-Z0-9-]*/
  XRANGEIDENTIFIERLOOSE = /#{NUMERICIDENTIFIERLOOSE.source}|x|X|\*/
  PRERELEASEIDENTIFIERLOOSE =  /(?:#{NUMERICIDENTIFIERLOOSE.source}|#{NONNUMERICIDENTIFIER.source})/
  PRERELEASELOOSE = /(?:-?(#{PRERELEASEIDENTIFIERLOOSE.source}(?:\.#{PRERELEASEIDENTIFIERLOOSE.source})*))/
  XRANGEPLAINLOOSE = /[v=\s]*(#{XRANGEIDENTIFIERLOOSE.source})(?:\.(#{XRANGEIDENTIFIERLOOSE.source})(?:\.(#{XRANGEIDENTIFIERLOOSE.source})(?:#{PRERELEASELOOSE.source})?#{BUILD.source}?)?)?/
  HYPHENRANGELOOSE = /^\s*(#{XRANGEPLAINLOOSE.source})\s+-\s+(#{XRANGEPLAINLOOSE.source})\s*$/
  PRERELEASEIDENTIFIER = /(?:#{NUMERICIDENTIFIER.source}|#{NONNUMERICIDENTIFIER.source})/
  PRERELEASE = /(?:-(#{PRERELEASEIDENTIFIER.source}(?:\.#{PRERELEASEIDENTIFIER.source})*))/
  XRANGEIDENTIFIER = /#{NUMERICIDENTIFIER.source}|x|X|\*/
  XRANGEPLAIN = /[v=\s]*(#{XRANGEIDENTIFIER.source})(?:\.(#{XRANGEIDENTIFIER.source})(?:\.(#{XRANGEIDENTIFIER.source})(?:#{PRERELEASE.source})?#{BUILD.source}?)?)?/
  HYPHENRANGE = /^\s*(#{XRANGEPLAIN.source})\s+-\s+(#{XRANGEPLAIN.source})\s*$/
  MAINVERSIONLOOSE = /(#{NUMERICIDENTIFIERLOOSE.source})\.(#{NUMERICIDENTIFIERLOOSE.source})\.(#{NUMERICIDENTIFIERLOOSE.source})/
  LOOSEPLAIN = /[v=\s]*#{MAINVERSIONLOOSE.source}#{PRERELEASELOOSE.source}?#{BUILD.source}?/
  GTLT = /((?:<|>)?=?)/
  COMPARATORTRIM = /(\s*)#{GTLT.source}\s*(#{LOOSEPLAIN.source}|#{XRANGEPLAIN.source})/
  LONETILDE = /(?:~>?)/
  TILDETRIM = /(\s*)#{LONETILDE.source}\s+/
  LONECARET = /(?:\^)/
  CARETTRIM = /(\s*)#{LONECARET.source}\s+/
  STAR = /(<|>)?=?\s*\*/
  CARET = /^#{LONECARET.source}#{XRANGEPLAIN.source}$/
  CARETLOOSE = /^#{LONECARET.source}#{XRANGEPLAINLOOSE.source}$/
  MAINVERSION = /(#{NUMERICIDENTIFIER.source})\.(#{NUMERICIDENTIFIER.source})\.(#{NUMERICIDENTIFIER.source})/
  FULLPLAIN = /v?#{MAINVERSION.source}#{PRERELEASE.source}?#{BUILD.source}?/
  FULL = /^#{FULLPLAIN.source}$/
  LOOSE = /^#{LOOSEPLAIN.source}$/
  TILDE = /^#{LONETILDE.source}#{XRANGEPLAIN.source}$/
  TILDELOOSE = /^#{LONETILDE.source}#{XRANGEPLAINLOOSE.source}$/
  XRANGE = /^#{GTLT.source}\s*#{XRANGEPLAIN.source}$/
  XRANGELOOSE = /^#{GTLT.source}\s*#{XRANGEPLAINLOOSE.source}$/
  COMPARATOR = /^#{GTLT.source}\s*(#{FULLPLAIN.source})$|^$/
  COMPARATORLOOSE = /^#{GTLT.source}\s*(#{LOOSEPLAIN.source})$|^$/

  ANY = {}

  MAX_LENGTH = 256

  class InvalidIncrement < StandardError; end
  class InvalidVersion < StandardError; end
  class InvalidComparator < StandardError; end
  class InvalidRange < StandardError; end

  def self.ltr?(version, range, loose: false, platform: nil)
    outside?(version, range, '<', loose: loose, platform: platform)
  end

  def self.gtr?(version, range, loose: false, platform: nil)
    outside?(version, range, '>', loose: loose, platform: platform)
  end

  def self.cmp(a, op, b, loose: false)
    case op
    when '==='
      a = a.version if !a.is_a?(String)
      b = b.version if !b.is_a?(String)
      a == b
    when '!=='
      a = a.version if !a.is_a?(String)
      b = b.version if !b.is_a?(String)
      a != b
    when '', '=', '=='
      eq?(a, b, loose: loose)
    when '!='
      neq?(a, b, loose: loose)
    when '>'
      gt?(a, b, loose: loose)
    when '>='
      gte?(a, b, loose: loose)
    when '<'
      lt?(a, b, loose: loose)
    when '<='
      lte?(a, b, loose: loose)
    else
      raise 'Invalid operator: ' + op
    end
  end

  def self.outside?(version, range, hilo, loose: false, platform: nil)
    version = Version.new(version, loose: loose)
    range = Range.new(range, loose: loose, platform: platform)

    return false if satisfies?(version, range, loose: loose, platform: platform)

    case hilo
    when '>'
      comp = '>'
      ecomp = '>='
    when '<'
      comp = '<'
      ecomp = '<='
    end

    range.set.each do |comparators|
      high = nil
      low = nil

      comparators.each do |comparator|
        if comparator.semver == ANY
          comparator = Comparator.new('>=0.0.0', loose)
        end

        high = high || comparator
        low = low || comparator

        case hilo
        when '>'
          if gt?(comparator.semver, high.semver, loose: loose)
            high = comparator
          elsif lt?(comparator.semver, low.semver, loose: loose)
            low = comparator
          end
        when '<'
          if lt?(comparator.semver, high.semver, loose: loose)
            high = comparator
          elsif gt?(comparator.semver, low.semver, loose: loose)
            low = comparator
          end
        end
      end

      return false if (high.operator == comp || high.operator == ecomp)

      case hilo
      when '>'
        if (low.operator.empty? || low.operator == comp) && lte?(version, low.semver, loose: loose)
          return false;
        elsif (low.operator == ecomp && lt?(version, low.semver, loose: loose))
          return false;
        end
      when '<'
        if (low.operator.empty? || low.operator == comp) && gte?(version, low.semver, loose: loose)
          return false;
        elsif low.operator == ecomp && gt?(version, low.semver, loose: loose)
          return false;
        end
      end
    end
    true
  end

  def self.satisfies?(version, range, loose: false, platform: nil)
    if valid?(range, loose: loose) 
      return version == range
    end
    begin
      Range.new(range, loose: loose, platform: platform).test(version)
    rescue
      false
    end
  end

  def self.filter(versions, range, loose: false, platform: nil)
    return [] if !valid_range(range, loose: loose, platform: platform)

    versions.filter { |v| SemanticRange.satisfies?(v, range, loose: loose, platform: platform) }
  end

  def self.max_satisfying(versions, range, loose: false, platform: nil)
    versions.select { |version|
      satisfies?(version, range, loose: loose, platform: platform)
    }.sort { |a, b|
      rcompare(a, b, loose: loose)
    }[0] || nil
  end

  def self.valid_range(range, loose: false, platform: nil)
    begin
      r = Range.new(range, loose: loose, platform: platform).range
      r = '*' if r.nil? || r.empty?
      r
    rescue
      nil
    end
  end

  def self.compare(a, b, loose: false)
    Version.new(a, loose: loose).compare(b)
  end

  def self.compare_loose(a, b)
    compare(a, b, loose: true)
  end

  def self.rcompare(a, b, loose: false)
    compare(b, a, loose: true)
  end

  def self.sort(list, loose: false)
    # TODO
  end

  def self.rsort(list, loose: false)
    # TODO
  end

  def self.lt?(a, b, loose: false)
    compare(a, b, loose: loose) < 0
  end

  def self.gt?(a, b, loose: false)
    compare(a, b, loose: loose) > 0
  end

  def self.eq?(a, b, loose: false)
    compare(a, b, loose: loose) == 0
  end

  def self.neq?(a, b, loose: false)
    compare(a, b, loose: loose) != 0
  end

  def self.gte?(a, b, loose: false)
    compare(a, b, loose: loose) >= 0
  end

  def self.lte?(a, b, loose: false)
    compare(a, b, loose: loose) <= 0
  end

  def self.valid?(version, loose: false)
    return false unless version.is_a?(String)

    stripped_version = version.strip
    return false if stripped_version.length > MAX_LENGTH

    rxp = loose ? LOOSE : FULL
    return rxp.match?(stripped_version)
  end

  def self.valid(version, loose: false)
    v = parse(version, loose: loose)
    return v ? v.version : nil
  end

  def self.clean(version, loose: false)
    s = parse(version.strip.gsub(/^[=v]+/, ''), loose: loose)
    return s ? s.version : nil
  end

  def self.parse(version, loose: false)
    return version if version.is_a?(Version)
    return nil unless valid?(version, loose: loose)

    Version.new(version.strip, loose: loose)
  end

  def self.increment!(version, release, identifier, loose: false)
    Version.new(version, loose: loose).increment!(release, identifier).version
  rescue InvalidIncrement, InvalidVersion
    nil
  end

  def self.diff(a, b)
    a = Version.new(a, loose: false) unless a.kind_of?(Version)
    b = Version.new(b, loose: false) unless b.kind_of?(Version)
    pre_diff = a.prerelease.to_s != b.prerelease.to_s
    pre = pre_diff ? 'pre' : ''
    return "#{pre}major" if a.major != b.major
    return "#{pre}minor" if a.minor != b.minor
    return "#{pre}patch" if a.patch != b.patch
    return "prerelease"  if pre_diff
  end

  def self.to_comparators(range, loose: false, platform: nil)
    Range.new(range, loose: loose, platform: platform).set.map do |comp|
      comp.map(&:to_s)
    end
  end

  class << self
    # Support for older non-inquisitive method versions
    alias_method :gt, :gt?
    alias_method :gtr, :gtr?
    alias_method :gte, :gte?
    alias_method :lt, :lt?
    alias_method :ltr, :ltr?
    alias_method :lte, :lte?
    alias_method :eq, :eq?
    alias_method :neq, :neq?
    alias_method :outside, :outside?
    alias_method :satisfies, :satisfies?
  end
end
