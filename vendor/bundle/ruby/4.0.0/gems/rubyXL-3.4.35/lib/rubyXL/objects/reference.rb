module RubyXL
  class Reference
    ROW_MAX = 1024 * 1024
    COL_MAX = 16393

    attr_reader :row_range, :col_range

    # RubyXL::Reference.new(row, col)
    # RubyXL::Reference.new(row_from, row_to, col_from, col_to)
    # RubyXL::Reference.new(reference_string)
    # RubyXL::Reference.new(row_from:, row_to:, col_from:, col_to:)
    def initialize(*params)
      row_from = row_to = col_from = col_to = nil

      case params.size
      when 4 then row_from, row_to, col_from, col_to = params
      when 2 then row_from, col_from = params
      when 1 then
        case params.first
        when Hash then
          row_from, row_to, col_from, col_to = params.first.fetch_values(:row_from, :row_to, :col_from, :col_to)
        when String then
          from, to = params[0].split(':')
          row_from, col_from = self.class.ref2ind(from)
          row_to, col_to = self.class.ref2ind(to) unless to.nil?
        else
          raise ArgumentError.new("invalid value for #{self.class}: #{params[0].inspect}") unless params[0].is_a?(String)
        end
      end

      @row_range = Range.new(row_from || 0, row_to || row_from || ROW_MAX)
      @col_range = Range.new(col_from || 0, col_to || col_from || COL_MAX)
    end

    def single_cell?
      (@row_range.begin == @row_range.end) && (@col_range.begin == @col_range.end)
    end

    def valid?
      !(row_range.begin.negative? || col_range.begin.negative?)
    end

    def first_row
      @row_range.begin
    end

    def last_row
      @row_range.end
    end

    def first_col
      @col_range.begin
    end

    def last_col
      @col_range.end
    end

    def ==(other)
      !other.nil? && (@row_range == other.row_range) && (@col_range == other.col_range)
    end

    def cover?(other)
      !other.nil? && (@row_range.cover?(other.row_range.begin) &&
                      @row_range.cover?(other.row_range.end) &&
                      @col_range.cover?(other.col_range.begin) &&
                      @col_range.cover?(other.col_range.end))
    end

    def to_s
      if single_cell? then
        self.class.ind2ref(@row_range.begin, @col_range.begin)
      else
        self.class.ind2ref(@row_range.begin, @col_range.begin) + ':' +
                           self.class.ind2ref(@row_range.end, @col_range.end)
      end
    end

    def inspect
      if single_cell? then
        "#<#{self.class} @row=#{@row_range.begin} @col=#{@col_range.begin}>"
      else
        "#<#{self.class} @row_range=#{@row_range} @col_range=#{@col_range}>"
      end
    end

    # Converts +row+ and +col+ zero-based indices to Excel-style cell reference
    # <0> A...Z, AA...AZ, BA... ...ZZ, AAA... ...AZZ, BAA... ...XFD <16383>
    def self.ind2ref(row = 0, col = 0)
      str = ''

      loop do
        x = col % 26
        str = ('A'.ord + x).chr + str
        col = (col / 26).floor - 1
        break if col < 0
      end

      str += (row + 1).to_s
    end

    # Converts Excel-style cell reference to +row+ and +col+ zero-based indices.
    def self.ref2ind(str)
      return [ -1, -1 ] unless str =~ /\A([A-Z]+)(\d+)\Z/
      [ Regexp.last_match(2).to_i - 1,
        Regexp.last_match(1).each_byte.inject(0) { |col, chr| (col * 26) + (chr - 64) } - 1 ]
    end
  end

  class Sqref < Array
    def initialize(str)
      str.split.each { |ref_str| self << RubyXL::Reference.new(ref_str) }
    end

    def to_s
      self.collect(&:to_s).join(' ')
    end
  end
end
