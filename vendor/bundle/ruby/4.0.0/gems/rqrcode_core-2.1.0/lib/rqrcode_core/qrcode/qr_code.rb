# frozen_string_literal: true

module RQRCodeCore
  QRMODE = {
    mode_number: 1 << 0,      # 1 (binary: 0001)
    mode_alpha_numk: 1 << 1,  # 2 (binary: 0010)
    mode_8bit_byte: 1 << 2   # 4 (binary: 0100)
  }.freeze

  QRMODE_NAME = {
    number: :mode_number,
    alphanumeric: :mode_alpha_numk,
    byte_8bit: :mode_8bit_byte,
    multi: :mode_multi
  }.freeze

  QRERRORCORRECTLEVEL = {
    l: 1,
    m: 0,
    q: 3,
    h: 2
  }.freeze

  QRMASKPATTERN = {
    pattern000: 0,
    pattern001: 1,
    pattern010: 2,
    pattern011: 3,
    pattern100: 4,
    pattern101: 5,
    pattern110: 6,
    pattern111: 7
  }.freeze

  QRMASKCOMPUTATIONS = [
    proc { |i, j| (i + j) % 2 == 0 },
    proc { |i, j| i % 2 == 0 },
    proc { |i, j| j % 3 == 0 },
    proc { |i, j| (i + j) % 3 == 0 },
    proc { |i, j| ((i / 2).floor + (j / 3).floor) % 2 == 0 },
    proc { |i, j| (i * j) % 2 + (i * j) % 3 == 0 },
    proc { |i, j| ((i * j) % 2 + (i * j) % 3) % 2 == 0 },
    proc { |i, j| ((i * j) % 3 + (i + j) % 2) % 2 == 0 }
  ].freeze

  QRPOSITIONPATTERNLENGTH = (7 + 1) * 2 + 1
  QRFORMATINFOLENGTH = 15

  # http://web.archive.org/web/20110710094955/http://www.denso-wave.com/qrcode/vertable1-e.html
  # http://web.archive.org/web/20110710094955/http://www.denso-wave.com/qrcode/vertable2-e.html
  # http://web.archive.org/web/20110710094955/http://www.denso-wave.com/qrcode/vertable3-e.html
  # http://web.archive.org/web/20110710094955/http://www.denso-wave.com/qrcode/vertable4-e.html
  QRMAXBITS = {
    l: [152, 272, 440, 640, 864, 1088, 1248, 1552, 1856, 2192, 2592, 2960, 3424, 3688, 4184,
      4712, 5176, 5768, 6360, 6888, 7456, 8048, 8752, 9392, 10_208, 10_960, 11_744, 12_248,
      13_048, 13_880, 14_744, 15_640, 16_568, 17_528, 18_448, 19_472, 20_528, 21_616, 22_496, 23_648],
    m: [128, 224, 352, 512, 688, 864, 992, 1232, 1456, 1728, 2032, 2320, 2672, 2920, 3320, 3624,
      4056, 4504, 5016, 5352, 5712, 6256, 6880, 7312, 8000, 8496, 9024, 9544, 10_136, 10_984,
      11_640, 12_328, 13_048, 13_800, 14_496, 15_312, 15_936, 16_816, 17_728, 18_672],
    q: [104, 176, 272, 384, 496, 608, 704, 880, 1056, 1232, 1440, 1648, 1952, 2088, 2360, 2600, 2936,
      3176, 3560, 3880, 4096, 4544, 4912, 5312, 5744, 6032, 6464, 6968, 7288, 7880, 8264, 8920, 9368,
      9848, 10288, 10832, 11408, 12016, 12656, 13328],
    h: [72, 128, 208, 288, 368, 480, 528, 688, 800, 976, 1120, 1264, 1440, 1576, 1784,
      2024, 2264, 2504, 2728, 3080, 3248, 3536, 3712, 4112, 4304, 4768, 5024, 5288, 5608, 5960,
      6344, 6760, 7208, 7688, 7888, 8432, 8768, 9136, 9776, 10_208]
  }.freeze

  # StandardErrors

  class QRCodeArgumentError < ArgumentError; end

  class QRCodeRunTimeError < RuntimeError; end

  # == Creation
  #
  # QRCode objects expect only one required constructor parameter
  # and an optional hash of any other. Here's a few examples:
  #
  #  qr = RQRCodeCore::QRCode.new('hello world')
  #  qr = RQRCodeCore::QRCode.new('hello world', size: 1, level: :m, mode: :alphanumeric)
  #

  class QRCode
    attr_reader :modules, :module_count, :version

    # Expects a string or array (for multi-segment encoding) to be parsed in, other args are optional
    #
    #   # data - the string, QRSegment or array of Hashes (with data:, mode: keys) you wish to encode
    #   # size - the size (Integer) of the QR Code (defaults to smallest size needed to encode the data)
    #   # max_size - the max_size (Integer) of the QR Code (default RQRCodeCore::QRUtil.max_size)
    #   # level - the error correction level, can be:
    #      * Level :l 7%  of code can be restored
    #      * Level :m 15% of code can be restored
    #      * Level :q 25% of code can be restored
    #      * Level :h 30% of code can be restored (default :h)
    #   # mode - the mode of the QR Code (defaults to alphanumeric or byte_8bit, depending on the input data, only used when data is a string):
    #      * :number
    #      * :alphanumeric
    #      * :byte_8bit
    #
    #   qr = RQRCodeCore::QRCode.new('hello world', size: 1, level: :m, mode: :alphanumeric)
    #   segment_qr = QRCodeCore::QRCode.new({ data: 'foo', mode: :byte_8bit })
    #   multi_qr = RQRCodeCore::QRCode.new([{ data: 'foo', mode: :byte_8bit }, { data: 'bar1', mode: :alphanumeric }])

    def initialize(data, *args)
      options = extract_options!(args)

      level = (options[:level] || :h).to_sym
      max_size = options[:max_size] || QRUtil.max_size

      @data = case data
      when String
        QRSegment.new(data: data, mode: options[:mode])
      when Array
        raise QRCodeArgumentError, "Array must contain Hashes with :data and :mode keys" unless data.all? { |seg| seg.is_a?(Hash) && %i[data mode].all? { |s| seg.key? s } }
        data.map { |seg| QRSegment.new(**seg) }
      when QRSegment
        data
      else
        raise QRCodeArgumentError, "data must be a String, QRSegment, or an Array"
      end
      @error_correct_level = QRERRORCORRECTLEVEL[level]

      unless @error_correct_level
        raise QRCodeArgumentError, "Unknown error correction level `#{level.inspect}`"
      end

      size = options[:size] || minimum_version(limit: max_size)

      if size > max_size
        raise QRCodeArgumentError, "Given size greater than maximum possible size of #{QRUtil.max_size}"
      end

      @version = size
      @module_count = @version * 4 + QRPOSITIONPATTERNLENGTH
      @modules = Array.new(@module_count)
      @data_list = multi_segment? ? QRMulti.new(@data) : @data.writer
      @data_cache = nil
      make
    end

    # <tt>checked?</tt> is called with a +col+ and +row+ parameter. This will
    # return true or false based on whether that coordinate exists in the
    # matrix returned. It would normally be called while iterating through
    # <tt>modules</tt>. A simple example would be:
    #
    #  instance.checked?( 10, 10 ) => true
    #

    def checked?(row, col)
      if !row.between?(0, @module_count - 1) || !col.between?(0, @module_count - 1)
        raise QRCodeRunTimeError, "Invalid row/column pair: #{row}, #{col}"
      end
      @modules[row][col]
    end
    alias_method :dark?, :checked?
    extend Gem::Deprecate

    deprecate :dark?, :checked?, 2020, 1

    # This is a public method that returns the QR Code you have
    # generated as a string. It will not be able to be read
    # in this format by a QR Code reader, but will give you an
    # idea if the final outout. It takes two optional args
    # +:dark+ and +:light+ which are there for you to choose
    # how the output looks. Here's an example of it's use:
    #
    #  instance.to_s =>
    #  xxxxxxx x  x x   x x  xx  xxxxxxx
    #  x     x  xxx  xxxxxx xxx  x     x
    #  x xxx x  xxxxx x       xx x xxx x
    #
    #  instance.to_s( dark: 'E', light: 'Q' ) =>
    #  EEEEEEEQEQQEQEQQQEQEQQEEQQEEEEEEE
    #  EQQQQQEQQEEEQQEEEEEEQEEEQQEQQQQQE
    #  EQEEEQEQQEEEEEQEQQQQQQQEEQEQEEEQE
    #

    def to_s(*args)
      options = extract_options!(args)
      dark = options[:dark] || "x"
      light = options[:light] || " "
      quiet_zone_size = options[:quiet_zone_size] || 0

      rows = []

      @modules.each do |row|
        cols = light * quiet_zone_size
        row.each do |col|
          cols += (col ? dark : light)
        end
        rows << cols
      end

      quiet_zone_size.times do
        rows.unshift(light * (rows.first.length / light.size))
        rows << light * (rows.first.length / light.size)
      end
      rows.join("\n")
    end

    # Public overide as default inspect is very verbose
    #
    #  RQRCodeCore::QRCode.new('my string to generate', size: 4, level: :h)
    #  => QRCodeCore: @data='my string to generate', @error_correct_level=2, @version=4, @module_count=33
    #

    def inspect
      "QRCodeCore: @data='#{@data}', @error_correct_level=#{@error_correct_level}, @version=#{@version}, @module_count=#{@module_count}"
    end

    # Return a symbol for current error connection level
    def error_correction_level
      QRERRORCORRECTLEVEL.invert[@error_correct_level]
    end

    # Return true if this QR Code includes multiple encoded segments
    def multi_segment?
      @data.is_a?(Array)
    end

    # Return a symbol in QRMODE.keys for current mode used
    def mode
      case @data_list
      when QRNumeric
        :mode_number
      when QRAlphanumeric
        :mode_alpha_numk
      else
        :mode_8bit_byte
      end
    end

    protected

    def make # :nodoc:
      prepare_common_patterns
      make_impl(false, get_best_mask_pattern)
    end

    private

    def prepare_common_patterns # :nodoc:
      @modules.map! { |row| Array.new(@module_count) }

      place_position_probe_pattern(0, 0)
      place_position_probe_pattern(@module_count - 7, 0)
      place_position_probe_pattern(0, @module_count - 7)
      place_position_adjust_pattern
      place_timing_pattern

      @common_patterns = @modules.map(&:clone)
    end

    def make_impl(test, mask_pattern) # :nodoc:
      @modules = @common_patterns.map(&:clone)

      place_format_info(test, mask_pattern)
      place_version_info(test) if @version >= 7

      if @data_cache.nil?
        @data_cache = QRCode.create_data(
          @version, @error_correct_level, @data_list
        )
      end

      map_data(@data_cache, mask_pattern)
    end

    def place_position_probe_pattern(row, col) # :nodoc:
      (-1..7).each do |r|
        next unless (row + r).between?(0, @module_count - 1)

        (-1..7).each do |c|
          next unless (col + c).between?(0, @module_count - 1)

          is_vert_line = r.between?(0, 6) && (c == 0 || c == 6)
          is_horiz_line = c.between?(0, 6) && (r == 0 || r == 6)
          is_square = r.between?(2, 4) && c.between?(2, 4)

          is_part_of_probe = is_vert_line || is_horiz_line || is_square
          @modules[row + r][col + c] = is_part_of_probe
        end
      end
    end

    def get_best_mask_pattern # :nodoc:
      min_lost_point = 0
      pattern = 0

      8.times do |i|
        make_impl(true, i)
        lost_point = QRUtil.get_lost_points(modules)

        if i == 0 || min_lost_point > lost_point
          min_lost_point = lost_point
          pattern = i
        end
      end
      pattern
    end

    def place_timing_pattern # :nodoc:
      (8...@module_count - 8).each do |i|
        @modules[i][6] = @modules[6][i] = i % 2 == 0
      end
    end

    def place_position_adjust_pattern # :nodoc:
      positions = QRUtil.get_pattern_positions(@version)

      positions.each do |row|
        positions.each do |col|
          next unless @modules[row][col].nil?

          (-2..2).each do |r|
            (-2..2).each do |c|
              is_part_of_pattern = r.abs == 2 || c.abs == 2 || (r == 0 && c == 0)
              @modules[row + r][col + c] = is_part_of_pattern
            end
          end
        end
      end
    end

    def place_version_info(test) # :nodoc:
      bits = QRUtil.get_bch_version(@version)

      18.times do |i|
        mod = !test && ((bits >> i) & 1) == 1
        @modules[(i / 3).floor][ i % 3 + @module_count - 8 - 3 ] = mod
        @modules[i % 3 + @module_count - 8 - 3][ (i / 3).floor ] = mod
      end
    end

    def place_format_info(test, mask_pattern) # :nodoc:
      data = (@error_correct_level << 3 | mask_pattern)
      bits = QRUtil.get_bch_format_info(data)

      QRFORMATINFOLENGTH.times do |i|
        mod = !test && ((bits >> i) & 1) == 1

        # vertical
        row = if i < 6
          i
        elsif i < 8
          i + 1
        else
          @module_count - 15 + i
        end
        @modules[row][8] = mod

        # horizontal
        col = if i < 8
          @module_count - i - 1
        elsif i < 9
          15 - i - 1 + 1
        else
          15 - i - 1
        end
        @modules[8][col] = mod
      end

      # fixed module
      @modules[@module_count - 8][8] = !test
    end

    def map_data(data, mask_pattern) # :nodoc:
      inc = -1
      row = @module_count - 1
      bit_index = 7
      byte_index = 0

      (@module_count - 1).step(1, -2) do |col|
        col -= 1 if col <= 6

        loop do
          2.times do |c|
            if @modules[row][col - c].nil?
              dark = false
              if byte_index < data.size && !data[byte_index].nil?
                dark = ((QRUtil.rszf(data[byte_index], bit_index) & 1) == 1)
              end
              mask = QRUtil.get_mask(mask_pattern, row, col - c)
              dark = !dark if mask
              @modules[row][ col - c ] = dark
              bit_index -= 1

              if bit_index == -1
                byte_index += 1
                bit_index = 7
              end
            end
          end

          row += inc

          if row < 0 || @module_count <= row
            row -= inc
            inc = -inc
            break
          end
        end
      end
    end

    def minimum_version(limit: QRUtil.max_size, version: 1)
      raise QRCodeRunTimeError, "Data length exceed maximum capacity of version #{limit}" if version > limit

      max_size_bits = QRMAXBITS[error_correction_level][version - 1]

      size_bits = multi_segment? ? @data.sum { |seg| seg.size(version) } : @data.size(version)

      return version if size_bits < max_size_bits

      minimum_version(limit: limit, version: version + 1)
    end

    def extract_options!(arr) # :nodoc:
      arr.last.is_a?(::Hash) ? arr.pop : {}
    end

    class << self
      def count_max_data_bits(rs_blocks) # :nodoc:
        max_data_bytes = rs_blocks.reduce(0) do |sum, rs_block|
          sum + rs_block.data_count
        end

        max_data_bytes * 8
      end

      def create_data(version, error_correct_level, data_list) # :nodoc:
        rs_blocks = QRRSBlock.get_rs_blocks(version, error_correct_level)
        max_data_bits = QRCode.count_max_data_bits(rs_blocks)
        buffer = QRBitBuffer.new(version)

        data_list.write(buffer)
        buffer.end_of_message(max_data_bits)

        if buffer.get_length_in_bits > max_data_bits
          raise QRCodeRunTimeError, "code length overflow. (#{buffer.get_length_in_bits}>#{max_data_bits}). (Try a larger size!)"
        end

        buffer.pad_until(max_data_bits)

        QRCode.create_bytes(buffer, rs_blocks)
      end

      def create_bytes(buffer, rs_blocks) # :nodoc:
        offset = 0
        max_dc_count = 0
        max_ec_count = 0
        dcdata = Array.new(rs_blocks.size)
        ecdata = Array.new(rs_blocks.size)

        rs_blocks.each_with_index do |rs_block, r|
          dc_count = rs_block.data_count
          ec_count = rs_block.total_count - dc_count
          max_dc_count = [max_dc_count, dc_count].max
          max_ec_count = [max_ec_count, ec_count].max

          dcdata_block = Array.new(dc_count)
          dcdata_block.size.times do |i|
            dcdata_block[i] = 0xff & buffer.buffer[i + offset]
          end
          dcdata[r] = dcdata_block

          offset += dc_count
          rs_poly = QRUtil.get_error_correct_polynomial(ec_count)
          raw_poly = QRPolynomial.new(dcdata[r], rs_poly.get_length - 1)
          mod_poly = raw_poly.mod(rs_poly)

          ecdata_block = Array.new(rs_poly.get_length - 1)
          ecdata_block.size.times do |i|
            mod_index = i + mod_poly.get_length - ecdata_block.size
            ecdata_block[i] = (mod_index >= 0) ? mod_poly.get(mod_index) : 0
          end
          ecdata[r] = ecdata_block
        end

        total_code_count = rs_blocks.reduce(0) do |sum, rs_block|
          sum + rs_block.total_count
        end

        data = Array.new(total_code_count)
        index = 0

        max_dc_count.times do |i|
          rs_blocks.size.times do |r|
            if i < dcdata[r].size
              data[index] = dcdata[r][i]
              index += 1
            end
          end
        end

        max_ec_count.times do |i|
          rs_blocks.size.times do |r|
            if i < ecdata[r].size
              data[index] = ecdata[r][i]
              index += 1
            end
          end
        end

        data
      end
    end
  end
end
