# frozen_string_literal: true

module RQRCodeCore
  class QRUtil
    PATTERN_POSITION_TABLE = [
      [],
      [6, 18],
      [6, 22],
      [6, 26],
      [6, 30],
      [6, 34],
      [6, 22, 38],
      [6, 24, 42],
      [6, 26, 46],
      [6, 28, 50],
      [6, 30, 54],
      [6, 32, 58],
      [6, 34, 62],
      [6, 26, 46, 66],
      [6, 26, 48, 70],
      [6, 26, 50, 74],
      [6, 30, 54, 78],
      [6, 30, 56, 82],
      [6, 30, 58, 86],
      [6, 34, 62, 90],
      [6, 28, 50, 72, 94],
      [6, 26, 50, 74, 98],
      [6, 30, 54, 78, 102],
      [6, 28, 54, 80, 106],
      [6, 32, 58, 84, 110],
      [6, 30, 58, 86, 114],
      [6, 34, 62, 90, 118],
      [6, 26, 50, 74, 98, 122],
      [6, 30, 54, 78, 102, 126],
      [6, 26, 52, 78, 104, 130],
      [6, 30, 56, 82, 108, 134],
      [6, 34, 60, 86, 112, 138],
      [6, 30, 58, 86, 114, 142],
      [6, 34, 62, 90, 118, 146],
      [6, 30, 54, 78, 102, 126, 150],
      [6, 24, 50, 76, 102, 128, 154],
      [6, 28, 54, 80, 106, 132, 158],
      [6, 32, 58, 84, 110, 136, 162],
      [6, 26, 54, 82, 110, 138, 166],
      [6, 30, 58, 86, 114, 142, 170]
    ].freeze

    G15 = 1 << 10 | 1 << 8 | 1 << 5 | 1 << 4 | 1 << 2 | 1 << 1 | 1 << 0
    G18 = 1 << 12 | 1 << 11 | 1 << 10 | 1 << 9 | 1 << 8 | 1 << 5 | 1 << 2 | 1 << 0
    G15_MASK = 1 << 14 | 1 << 12 | 1 << 10 | 1 << 4 | 1 << 1

    DEMERIT_POINTS_1 = 3
    DEMERIT_POINTS_2 = 3
    DEMERIT_POINTS_3 = 40
    DEMERIT_POINTS_4 = 10

    BITS_FOR_MODE = {
      QRMODE[:mode_number] => [10, 12, 14],
      QRMODE[:mode_alpha_numk] => [9, 11, 13],
      QRMODE[:mode_8bit_byte] => [8, 16, 16]
    }.freeze

    # This value is used during the right shift zero fill step (rszf method).
    # Auto-set to 32 or 64 depending on system architecture (1.size * 8).
    #
    # PERFORMANCE IMPACT (64-bit vs 32-bit on 64-bit systems):
    # - Memory: 70-76% reduction (e.g., 37.91 MB → 9.10 MB for 100 small QR codes)
    # - Speed: 2-4% faster with 32-bit
    # - Objects: 85-87% fewer allocations
    # - All tests pass with ARCH_BITS=32
    #
    # RECOMMENDATION: Use RQRCODE_CORE_ARCH_BITS=32 even on 64-bit systems
    # for dramatic memory savings with no downsides. The QR code algorithm
    # doesn't require 64-bit integers—32-bit is sufficient for all operations.
    #
    # See test/benchmarks/ARCH_BITS_ANALYSIS.md for detailed benchmark data.
    ARCH_BITS = ENV.fetch("RQRCODE_CORE_ARCH_BITS", nil)&.to_i || 1.size * 8

    def self.max_size
      PATTERN_POSITION_TABLE.count
    end

    def self.get_bch_format_info(data)
      d = data << 10
      while QRUtil.get_bch_digit(d) - QRUtil.get_bch_digit(G15) >= 0
        d ^= (G15 << (QRUtil.get_bch_digit(d) - QRUtil.get_bch_digit(G15)))
      end
      ((data << 10) | d) ^ G15_MASK
    end

    def self.rszf(num, count)
      # right shift zero fill
      (num >> count) & ((1 << (ARCH_BITS - count)) - 1)
    end

    def self.get_bch_version(data)
      d = data << 12
      while QRUtil.get_bch_digit(d) - QRUtil.get_bch_digit(G18) >= 0
        d ^= (G18 << (QRUtil.get_bch_digit(d) - QRUtil.get_bch_digit(G18)))
      end
      (data << 12) | d
    end

    def self.get_bch_digit(data)
      digit = 0

      while data != 0
        digit += 1
        data = QRUtil.rszf(data, 1)
      end

      digit
    end

    def self.get_pattern_positions(version)
      PATTERN_POSITION_TABLE[version - 1]
    end

    def self.get_mask(mask_pattern, i, j)
      raise QRCodeRunTimeError, "bad mask_pattern: #{mask_pattern}" if mask_pattern > QRMASKCOMPUTATIONS.size

      QRMASKCOMPUTATIONS[mask_pattern].call(i, j)
    end

    def self.get_error_correct_polynomial(error_correct_length)
      a = QRPolynomial.new([1], 0)

      (0...error_correct_length).each do |i|
        a = a.multiply(QRPolynomial.new([1, QRMath.gexp(i)], 0))
      end

      a
    end

    def self.get_length_in_bits(mode, version)
      raise QRCodeRunTimeError, "Unknown mode: #{mode}" unless QRMODE.value?(mode)

      raise QRCodeRunTimeError, "Unknown version: #{version}" if version > 40

      if version.between?(1, 9)
        # 1 - 9
        macro_version = 0
      elsif version <= 26
        # 10 - 26
        macro_version = 1
      elsif version <= 40
        # 27 - 40
        macro_version = 2
      end

      BITS_FOR_MODE[mode][macro_version]
    end

    def self.get_lost_points(modules)
      demerit_points = 0

      demerit_points += QRUtil.demerit_points_1_same_color(modules)
      demerit_points += QRUtil.demerit_points_2_full_blocks(modules)
      demerit_points += QRUtil.demerit_points_3_dangerous_patterns(modules)
      demerit_points += QRUtil.demerit_points_4_dark_ratio(modules)

      demerit_points
    end

    def self.demerit_points_1_same_color(modules)
      demerit_points = 0
      module_count = modules.size
      max_index = module_count - 1

      # level1
      module_count.times do |row|
        modules_row = modules[row]

        module_count.times do |col|
          same_count = 0
          dark = modules_row[col]

          # Check 3x3 neighborhood, but skip center cell
          # Unroll loops and eliminate range objects for performance

          # Row above (row - 1)
          if row > 0
            row_above = modules[row - 1]
            same_count += 1 if col > 0 && dark == row_above[col - 1]
            same_count += 1 if dark == row_above[col]
            same_count += 1 if col < max_index && dark == row_above[col + 1]
          end

          # Same row
          same_count += 1 if col > 0 && dark == modules_row[col - 1]
          same_count += 1 if col < max_index && dark == modules_row[col + 1]

          # Row below (row + 1)
          if row < max_index
            row_below = modules[row + 1]
            same_count += 1 if col > 0 && dark == row_below[col - 1]
            same_count += 1 if dark == row_below[col]
            same_count += 1 if col < max_index && dark == row_below[col + 1]
          end

          demerit_points += (DEMERIT_POINTS_1 + same_count - 5) if same_count > 5
        end
      end

      demerit_points
    end

    def self.demerit_points_2_full_blocks(modules)
      demerit_points = 0
      module_count = modules.size
      max_row = module_count - 1

      # level 2: Check for 2x2 blocks of same color
      # Only need to check (module_count - 1) x (module_count - 1) positions
      max_row.times do |row|
        row_curr = modules[row]
        row_next = modules[row + 1]

        max_row.times do |col|
          # Check if all 4 modules in 2x2 block have same color
          # (count == 0: all false, count == 4: all true)
          val = row_curr[col]
          if val == row_next[col] && val == row_curr[col + 1] && val == row_next[col + 1]
            demerit_points += DEMERIT_POINTS_2
          end
        end
      end

      demerit_points
    end

    def self.demerit_points_3_dangerous_patterns(modules)
      demerit_points = 0
      module_count = modules.size
      pattern_len = 7
      max_start = module_count - pattern_len + 1

      # level 3: Check for dangerous pattern [dark, light, dark, dark, dark, light, dark]
      # Pattern: true, false, true, true, true, false, true (1:1:3:1:1 ratio)

      # Check rows
      modules.each do |row|
        max_start.times do |col|
          if row[col] && !row[col + 1] && row[col + 2] &&
              row[col + 3] && row[col + 4] && !row[col + 5] && row[col + 6]
            demerit_points += DEMERIT_POINTS_3
          end
        end
      end

      # Check columns
      module_count.times do |col|
        max_start.times do |row|
          if modules[row][col] && !modules[row + 1][col] && modules[row + 2][col] &&
              modules[row + 3][col] && modules[row + 4][col] && !modules[row + 5][col] && modules[row + 6][col]
            demerit_points += DEMERIT_POINTS_3
          end
        end
      end

      demerit_points
    end

    def self.demerit_points_4_dark_ratio(modules)
      # level 4
      dark_count = modules.reduce(0) do |sum, col|
        sum + col.count(true)
      end

      # Convert to float to prevent integer division
      ratio = dark_count.to_f / (modules.size * modules.size)
      ratio_delta = (100 * ratio - 50).abs / 5

      ratio_delta * DEMERIT_POINTS_4
    end
  end
end
