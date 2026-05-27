module SemanticRange
  VERSION = "3.1.1"

  class Version
    attr_reader :major, :minor, :patch, :prerelease

    def initialize(version, loose: false)
      @raw = version
      @loose = loose

      @raw = version.raw if version.is_a?(Version)

      match = @raw.to_s.strip.match(loose ? LOOSE : FULL)

      raise InvalidVersion.new(version) if match.nil?

      if String(version.to_s).length > MAX_LENGTH
        raise InvalidVersion.new("#{version} is too long")
      end

      @major = match[1] ? match[1].to_i : 0
      @minor = match[2] ? match[2].to_i : 0
      @patch = match[3] ? match[3].to_i : 0

      @prerelease = PreRelease.new match[4]

      @build = match[5] ? match[5].split('.') : []
    end

    def format
      v = "#{@major}.#{@minor}.#{@patch}"
      prerelease.length > 0 ? "#{v}-#{prerelease}" : v
    end

    def to_s
      @version
    end

    def version
      format
    end

    def raw
      version
    end

    def compare(other)
      other = Version.new(other, loose: @loose) unless other.is_a?(Version)
      res = truthy(compare_main(other)) || truthy(compare_pre(other))
      res.is_a?(FalseClass) ? 0 : res
    end

    def compare_main(other)
      other = Version.new(other, loose: @loose) unless other.is_a?(Version)
      truthy(self.class.compare_identifiers(@major, other.major)) ||
      truthy(self.class.compare_identifiers(@minor, other.minor)) ||
      truthy(self.class.compare_identifiers(@patch, other.patch))
    end

    def truthy(val)
      return val unless val.is_a?(Integer)
      val.zero? ? false : val
    end

    def compare_pre(other)
      prerelease <=> other.prerelease
    end

    def self.compare_identifiers(a,b)
      anum = /^[0-9]+$/.match(a.to_s)
      bnum = /^[0-9]+$/.match(b.to_s)

      if anum && bnum
        a = a.to_i
        b = b.to_i
      end

      return (anum && !bnum) ? -1 :
             (bnum && !anum) ? 1 :
             a < b ? -1 :
             a > b ? 1 :
             0;
    end

    def increment!(release, identifier)
      case release
      when 'premajor'
        @prerelease.clear!
        @patch = 0
        @minor = 0
        @major = @major + 1
        increment! 'pre', identifier
      when 'preminor'
        @prerelease.clear!
        @patch = 0
        @minor = @minor + 1
        increment! 'pre', identifier
      when 'prepatch'
        # If this is already a prerelease, it will bump to the next version
        # drop any prereleases that might already exist, since they are not
        # relevant at this point.
        @prerelease.clear!
        increment! 'patch', identifier
        increment! 'pre', identifier

        # If the input is a non-prerelease version, this acts the same as
        # prepatch.
      when 'prerelease'
        if @prerelease.empty?
          increment! 'patch', identifier
        end
        increment! 'pre', identifier
      when 'major'
        # If this is a pre-major version, bump up to the same major version.
        # Otherwise increment major.
        # 1.0.0-5 bumps to 1.0.0
        # 1.1.0 bumps to 2.0.0
        if @minor != 0 || @patch != 0 || @prerelease.empty?
          @major = @major + 1
        end
        @minor = 0
        @patch = 0
        @prerelease.clear!
      when 'minor'
        # If this is a pre-minor version, bump up to the same minor version.
        # Otherwise increment minor.
        # 1.2.0-5 bumps to 1.2.0
        # 1.2.1 bumps to 1.3.0
        if @patch != 0 || @prerelease.empty?
          @minor = @minor + 1
        end
        @patch = 0
        @prerelease.clear!
      when 'patch'
        # If this is not a pre-release version, it will increment the patch.
        # If it is a pre-release it will bump up to the same patch version.
        # 1.2.0-5 patches to 1.2.0
        # 1.2.0 patches to 1.2.1
        if @prerelease.empty?
          @patch = @patch + 1
        end
        @prerelease.clear!

        # This probably shouldn't be used publicly.
        # 1.0.0 "pre" would become 1.0.0-0 which is the wrong direction.
      when 'pre'
        @prerelease.increment!(identifier)
      else
        raise InvalidIncrement.new release
      end

      self
    end
  end
end
