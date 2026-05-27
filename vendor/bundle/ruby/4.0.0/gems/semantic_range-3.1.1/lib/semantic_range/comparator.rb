module SemanticRange
  class Comparator
    attr_reader :semver, :operator, :value
    def initialize(comp, loose)
      comp = comp.value if comp.is_a?(Comparator)
      @loose = loose

      parse(comp)

      @value = @semver == ANY ? '' : @operator + @semver.version
    end

    def to_s
      @value
    end

    def test(version)
      return true if @semver == ANY
      version = Version.new(version, @loose) if version.is_a?(String)
      SemanticRange.cmp(version, @operator, @semver, loose: @loose)
    end

    def parse(comp)
      m = comp.match(@loose ? COMPARATORLOOSE : COMPARATOR)
      raise InvalidComparator.new(comp) unless m

      @operator = m[1]
      @operator = '' if @operator == '='

      @semver = !m[2] ? ANY : Version.new(m[2], loose: @loose)
    end

    def intersects?(comp, loose: false, platform: nil)
      comp = Comparator.new(comp, loose)

      if @operator == ''
        range_b = Range.new(comp.value, loose: loose, platform: platform)
        SemanticRange.satisfies?(@value, range_b, loose: loose, platform: platform)
      elsif comp.operator == ''
        range_a = Range.new(@value, loose: loose, platform: platform)
        SemanticRange.satisfies?(comp.semver, range_a, loose: loose, platform: platform)
      else
        same_direction_increasing      = (@operator == '>=' || @operator == '>') && (comp.operator == '>=' || comp.operator == '>')
        same_direction_decreasing      = (@operator == '<=' || @operator == '<') && (comp.operator == '<=' || comp.operator == '<')
        same_version                   = @semver.raw == comp.semver.raw
        different_directions_inclusive = (@operator == '>=' || @operator == '<=') && (comp.operator == '>=' || comp.operator == '<=')
        opposite_directions_lte        = SemanticRange.cmp(@semver, '<', comp.semver, loose: loose) &&
            ((@operator == '>=' || @operator == '>') && (comp.operator == '<=' || comp.operator == '<'))
        opposite_directions_gte        = SemanticRange.cmp(@semver, '>', comp.semver, loose: loose) &&
            ((@operator == '<=' || @operator == '<') && (comp.operator == '>=' || comp.operator == '>'))

        same_direction_increasing || same_direction_decreasing || (same_version && different_directions_inclusive) ||
            opposite_directions_lte || opposite_directions_gte
      end
    end

    def satisfies_range?(range, loose: false, platform: nil)
      range = Range.new(range, loose: loose, platform: platform)

      range.set.any? do |comparators|
        comparators.all? do |comparator|
          intersects?(comparator, loose: loose, platform: platform)
        end
      end
    end

    # Support for older non-inquisitive method versions
    alias_method :intersects, :intersects?
    alias_method :satisfies_range, :satisfies_range?
  end
end
