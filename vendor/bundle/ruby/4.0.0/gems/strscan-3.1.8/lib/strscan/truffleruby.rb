# frozen_string_literal: true
# truffleruby_primitives: true

class StringScanner
  class Error < StandardError
  end
  # :stopdoc:
  unless ::Object.const_defined?(:ScanError)
    ::Object::ScanError = Error
    ::Object.deprecate_constant :ScanError
  end

  Version = '3.1.8'
  Id = '$Id$'

  def self.must_C_version = self
  # :startdoc:

  attr_reader :string, :pos
  alias_method :pointer, :pos

  def initialize(string, options = nil, fixed_anchor: false)
    @string = Primitive.convert_with_to_str(string)
    @fixed_anchor = Primitive.as_boolean(fixed_anchor)
    @pos = 0
    @last_match = nil
  end

  def inspect
    return "#<#{Primitive.class(self)} (uninitialized)>" unless @string
    return "#<#{Primitive.class(self)} fin>" if eos?

    before =
      if @pos == 0
        ''
      elsif @pos < 5
        "#{@string.byteslice(0, @pos).inspect} "
      else
        "#{('...' + @string.byteslice(@pos - 5, 5)).inspect} "
      end

    after =
      if @pos >= @string.bytesize - 5
        " #{@string.byteslice(@pos..).inspect}"
      else
        " #{(@string.byteslice(@pos, 5) + '...').inspect}"
      end

    "#<#{Primitive.class(self)} #{@pos}/#{@string.bytesize} #{before}@#{after}>"
  end

  def pos=(new_pos)
    if new_pos < 0
      new_pos += @string.bytesize
    end
    raise RangeError, 'index out of range' if new_pos < 0
    raise RangeError, 'index out of range' if new_pos > @string.bytesize
    @pos = new_pos
  end
  alias_method :pointer=, :pos=

  def charpos = Primitive.string_byte_index_to_character_index(@string, @pos)

  def rest = @string.byteslice(@pos, @string.bytesize)

  def rest_size = @string.bytesize - @pos

  def concat(more_string)
    @string.concat(Primitive.convert_with_to_str(more_string))
    self
  end
  alias_method :<<, :concat

  def string=(other_string)
    @string = Primitive.convert_with_to_str(other_string)
    @pos = 0
    @last_match = nil
    other_string
  end

  def reset
    @pos = 0
    @last_match = nil
    self
  end

  def terminate
    @pos = @string.bytesize
    @last_match = nil
    self
  end

  def unscan
    if @last_match
      @pos = Primitive.match_data_byte_begin(@last_match, 0)
      @last_match = nil
      self
    else
      raise Error, 'unscan failed: previous match record not exist'
    end
  end

  # Predicates

  def fixed_anchor? = @fixed_anchor

  def beginning_of_line?
    @pos == 0 or @string.byteslice(@pos-1, 1) == "\n"
  end
  alias_method :bol?, :beginning_of_line?

  def eos?
    @pos >= @string.bytesize
  end

  def rest?
    !eos?
  end

  # MatchData-like methods

  def matched? = !Primitive.nil?(@last_match)

  def matched = @last_match&.to_s

  def [](group)
    raise TypeError, 'no implicit conversion of Range into Integer' if Primitive.is_a?(group, Range)

    if @last_match
      @last_match[group]
    else
      nil
    end
  end

  def values_at(*groups) = @last_match&.values_at(*groups)

  def captures = @last_match&.captures

  def size = @last_match&.size

  def pre_match = @last_match&.pre_match

  def post_match = @last_match&.post_match

  def named_captures = @last_match&.named_captures || {}

  def matched_size
    if @last_match
      Primitive.match_data_byte_end(@last_match, 0) - Primitive.match_data_byte_begin(@last_match, 0)
    end
  end

  # Scan-like methods

  def peek(length)
    raise ArgumentError, 'negative string size (or size too big)' if length < 0
    @string.byteslice(@pos, length)
  end

  def peek_byte = @string.getbyte(@pos)

  def get_byte
    return nil if eos?

    byte = @string.byteslice(@pos, 1)
    to = @pos + 1
    @last_match = Primitive.matchdata_create_single_group(byte, @string, @pos, to)
    @pos = to
    byte
  end

  def scan_byte
    return nil if eos?

    byte_value = @string.getbyte(@pos)
    get_byte
    byte_value
  end

  def getch = scan(/./m)

  def scan_integer(base: 10)
    case base
    when 10
      scan(/[+-]?\d+/)&.to_i
    when 16
      scan(/[+-]?(0x)?[0-9a-fA-F]+/)&.to_i(16)
    else
      raise ArgumentError, "Unsupported integer base: #{base.inspect}, expected 10 or 16"
    end
  end

  def scan_full(pattern, advance_pointer, return_string)
    if advance_pointer
      if return_string
        scan(pattern)
      else
        skip(pattern)
      end
    else
      if return_string
        check(pattern)
      else
        match?(pattern)
      end
    end
  end
  Primitive.always_split self, :scan_full

  def search_full(pattern, advance_pointer, return_string)
    if advance_pointer
      if return_string
        scan_until(pattern)
      else
        skip_until(pattern)
      end
    else
      if return_string
        check_until(pattern)
      else
        exist?(pattern)
      end
    end
  end
  Primitive.always_split self, :search_full

  # Keep the following 8 methods in sync, they are small variations of one another

  # Matches at start methods

  # Matches at start, returns matched string, does not advance position
  def check(pattern)
    prev = @pos
    if Primitive.is_a?(pattern, Regexp)
      start = @fixed_anchor ? 0 : prev
      @last_match = Primitive.regexp_match_at_start(pattern, @string, prev, start)
      if @last_match
        @last_match.to_s
      end
    else
      pattern = Primitive.convert_with_to_str(pattern)
      if rest.start_with?(pattern)
        to = prev + pattern.bytesize
        @last_match = Primitive.matchdata_create_single_group(pattern, @string, prev, to)
        pattern
      else
        @last_match = nil
      end
    end
  end
  Primitive.always_split self, :check

  # Matches at start, returns matched string, advances position
  def scan(pattern)
    prev = @pos
    if Primitive.is_a?(pattern, Regexp)
      start = @fixed_anchor ? 0 : prev
      @last_match = Primitive.regexp_match_at_start(pattern, @string, prev, start)
      if @last_match
        @pos = Primitive.match_data_byte_end(@last_match, 0)
        @last_match.to_s
      end
    else
      pattern = Primitive.convert_with_to_str(pattern)
      if rest.start_with?(pattern)
        to = prev + pattern.bytesize
        @last_match = Primitive.matchdata_create_single_group(pattern, @string, prev, to)
        @pos = to
        pattern
      else
        @last_match = nil
      end
    end
  end
  Primitive.always_split self, :scan

  # Matches at start, returns matched bytesize, does not advance position
  def match?(pattern)
    prev = @pos
    if Primitive.is_a?(pattern, Regexp)
      start = @fixed_anchor ? 0 : prev
      @last_match = Primitive.regexp_match_at_start(pattern, @string, prev, start)
      if @last_match
        to = Primitive.match_data_byte_end(@last_match, 0)
        to - prev
      end
    else
      pattern = Primitive.convert_with_to_str(pattern)
      if rest.start_with?(pattern)
        to = prev + pattern.bytesize
        @last_match = Primitive.matchdata_create_single_group(pattern, @string, prev, to)
        to - prev
      else
        @last_match = nil
      end
    end
  end
  Primitive.always_split self, :match?

  # Matches at start, returns matched bytesize, advances position
  def skip(pattern)
    prev = @pos
    if Primitive.is_a?(pattern, Regexp)
      start = @fixed_anchor ? 0 : prev
      @last_match = Primitive.regexp_match_at_start(pattern, @string, prev, start)
      if @last_match
        to = Primitive.match_data_byte_end(@last_match, 0)
        @pos = to
        to - prev
      end
    else
      pattern = Primitive.convert_with_to_str(pattern)
      if rest.start_with?(pattern)
        to = prev + pattern.bytesize
        @last_match = Primitive.matchdata_create_single_group(pattern, @string, prev, to)
        @pos = to
        to - prev
      else
        @last_match = nil
      end
    end
  end
  Primitive.always_split self, :skip

  # Matches anywhere methods

  # Matches anywhere, returns matched string, does not advance position
  def check_until(pattern)
    prev = @pos
    if Primitive.is_a?(pattern, Regexp)
      start = @fixed_anchor ? 0 : prev
      @last_match = Primitive.regexp_search_with_start(pattern, @string, prev, start)
      if @last_match
        to = Primitive.match_data_byte_end(@last_match, 0)
        @string.byteslice(prev, to - prev)
      end
    else
      pattern = Primitive.convert_with_to_str(pattern)
      if from = @string.byteindex(pattern, prev)
        to = from + pattern.bytesize
        @last_match = Primitive.matchdata_create_single_group(pattern, @string, from, to)
        @string.byteslice(prev, to - prev)
      else
        @last_match = nil
      end
    end
  end
  Primitive.always_split self, :check_until

  # Matches anywhere, returns matched string, advances position
  def scan_until(pattern)
    prev = @pos
    if Primitive.is_a?(pattern, Regexp)
      start = @fixed_anchor ? 0 : prev
      @last_match = Primitive.regexp_search_with_start(pattern, @string, prev, start)
      if @last_match
        to = Primitive.match_data_byte_end(@last_match, 0)
        @pos = to
        @string.byteslice(prev, to - prev)
      end
    else
      pattern = Primitive.convert_with_to_str(pattern)
      if from = @string.byteindex(pattern, prev)
        to = from + pattern.bytesize
        @last_match = Primitive.matchdata_create_single_group(pattern, @string, from, to)
        @pos = to
        @string.byteslice(prev, to - prev)
      else
        @last_match = nil
      end
    end
  end
  Primitive.always_split self, :scan_until

  # Matches anywhere, returns matched bytesize, does not advance position
  def exist?(pattern)
    prev = @pos
    if Primitive.is_a?(pattern, Regexp)
      start = @fixed_anchor ? 0 : prev
      @last_match = Primitive.regexp_search_with_start(pattern, @string, prev, start)
      if @last_match
        to = Primitive.match_data_byte_end(@last_match, 0)
        to - prev
      end
    else
      pattern = Primitive.convert_with_to_str(pattern)
      if from = @string.byteindex(pattern, prev)
        to = from + pattern.bytesize
        @last_match = Primitive.matchdata_create_single_group(pattern, @string, from, to)
        to - prev
      else
        @last_match = nil
      end
    end
  end
  Primitive.always_split self, :exist?

  # Matches anywhere, returns matched bytesize, advances position
  def skip_until(pattern)
    prev = @pos
    if Primitive.is_a?(pattern, Regexp)
      start = @fixed_anchor ? 0 : prev
      @last_match = Primitive.regexp_search_with_start(pattern, @string, prev, start)
      if @last_match
        to = Primitive.match_data_byte_end(@last_match, 0)
        @pos = to
        to - prev
      end
    else
      pattern = Primitive.convert_with_to_str(pattern)
      if from = @string.byteindex(pattern, prev)
        to = from + pattern.bytesize
        @last_match = Primitive.matchdata_create_single_group(pattern, @string, from, to)
        @pos = to
        to - prev
      else
        @last_match = nil
      end
    end
  end
  Primitive.always_split self, :skip_until
end
