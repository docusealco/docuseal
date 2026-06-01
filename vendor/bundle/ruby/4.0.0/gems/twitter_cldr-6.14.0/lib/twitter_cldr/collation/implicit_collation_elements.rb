# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

module TwitterCldr
  module Collation

    # ImplicitCollationElements generates implicit collation elements for code points (including some CJK characters),
    # that are not explicitly mentioned in the collation elements table.
    #
    # This module was ported from the ICU4J library (ImplicitCEGenerator class). See NOTICE file for license information.
    #
    module ImplicitCollationElements

      DEFAULT_SECONDARY_AND_TERTIARY = 5

      class << self

        def for_code_point(code_point)
          [[primary_weight(swapCJK(code_point) + 1), DEFAULT_SECONDARY_AND_TERTIARY, DEFAULT_SECONDARY_AND_TERTIARY]]
        end

        private

        # Generates the primary weight of the implicit CE for a given code point.
        #
        def primary_weight(code_point)
          byte0 = code_point - MIN_4_BOUNDARY

          if byte0 < 0
            byte1 = code_point / FINAL_3_COUNT
            byte0 = code_point % FINAL_3_COUNT

            byte2 = byte1 / MEDIAL_COUNT
            byte1 %= MEDIAL_COUNT

            # spread out, leaving gap at start
            byte0 = MIN_TRAIL + byte0 * FINAL_3_MULTIPLIER

            # offset
            byte1 += MIN_TRAIL
            byte2 += MIN_PRIMARY

            (byte2 << 16) + (byte1 << 8) + byte0
          else
            byte1 = byte0 / FINAL_4_COUNT
            byte0 %= FINAL_4_COUNT

            byte2 = byte1 / MEDIAL_COUNT
            byte1 %= MEDIAL_COUNT

            byte3 = byte2 / MEDIAL_COUNT
            byte2 %= MEDIAL_COUNT

            # spread out, leaving gap at start
            byte0 = MIN_TRAIL + byte0 * FINAL_4_MULTIPLIER

            # offset
            byte1 += MIN_TRAIL
            byte2 += MIN_TRAIL
            byte3 += MIN_4_PRIMARY

            (byte3 << 24) + (byte2 << 16) + (byte1 << 8) + byte0
          end
        end

        # Method used to:
        #   a) collapse two different Han ranges from UCA into one (in the right order)
        #   b) bump any non-CJK characters by NON_CJK_OFFSET.
        #
        # The relevant blocks are:
        # A:  4E00..9FFF; CJK Unified Ideographs
        #     F900..FAFF; CJK Compatibility Ideographs
        # B:  3400..4DBF; CJK Unified Ideographs Extension A
        #     20000..XX;  CJK Unified Ideographs Extension B (and others later on)
        #
        # As long as
        #   no new B characters are allocated between 4E00 and FAFF, and
        #   no new A characters are outside of this range,
        # (very high probability) this simple code will work.
        #
        # The reordered blocks are:
        #   Block1 is CJK
        #   Block2 is CJK_COMPAT_USED
        #   Block3 is CJK_A
        #   (all contiguous)
        #
        # Any other CJK gets its normal code point.
        #
        # When we reorder Block1, we make sure that it is at the very start, so that it will use a 3-byte form.
        #
        def swapCJK(code_point)
          if code_point >= CJK_BASE
            return code_point - CJK_BASE                                      if code_point < CJK_LIMIT
            return code_point + NON_CJK_OFFSET                                if code_point < CJK_COMPAT_USED_BASE
            return code_point - CJK_COMPAT_USED_BASE + (CJK_LIMIT - CJK_BASE) if code_point < CJK_COMPAT_USED_LIMIT
            return code_point + NON_CJK_OFFSET                                if code_point < CJK_B_BASE
            return code_point                                                 if code_point < CJK_B_LIMIT # non-BMP-CJK
            return code_point + NON_CJK_OFFSET                                if code_point < CJK_C_BASE
            return code_point                                                 if code_point < CJK_C_LIMIT # non-BMP-CJK
            return code_point + NON_CJK_OFFSET                                if code_point < CJK_D_BASE
            return code_point                                                 if code_point < CJK_D_LIMIT # non-BMP-CJK

            return code_point + NON_CJK_OFFSET # non-CJK
          end

          return code_point + NON_CJK_OFFSET if code_point < CJK_A_BASE
          return code_point - CJK_A_BASE + (CJK_LIMIT - CJK_BASE) + (CJK_COMPAT_USED_LIMIT - CJK_COMPAT_USED_BASE) if code_point < CJK_A_LIMIT

          code_point + NON_CJK_OFFSET # non-CJK
        end

      end

      # primary value
      MIN_PRIMARY = 0xE0
      MAX_PRIMARY = 0xe4

      # final byte
      MIN_TRAIL = 0x04
      MAX_TRAIL = 0xFE

      # gap for tailoring of 3-byte forms
      GAP_3 = 1

      # number of 3-byte primaries that can be used
      PRIMARIES_3_COUNT = 1

      # 2 * [Unicode range] + 2
      MAX_INPUT = 0x220001

      # medials can use full range
      MEDIAL_COUNT       = MAX_TRAIL - MIN_TRAIL + 1

      # number of values we can use in trailing bytes
      # leave room for empty values between AND above, e.g., if gap = 2
      #   range 3..7 => +3 -4 -5 -6 -7: so 1 value
      #   range 3..8 => +3 -4 -5 +6 -7 -8: so 2 values
      #   range 3..9 => +3 -4 -5 +6 -7 -8 -9: so 2 values
      FINAL_3_MULTIPLIER = GAP_3 + 1
      FINAL_3_COUNT      = MEDIAL_COUNT / FINAL_3_MULTIPLIER

      # find out how many values fit in each form
      THREE_BYTE_COUNT = MEDIAL_COUNT * FINAL_3_COUNT

      # now determine where the 3/4 boundary is
      # we use 3 bytes below the boundary, and 4 above
      PRIMARIES_AVAILABLE = MAX_PRIMARY - MIN_PRIMARY + 1
      PRIMARIES_4_COUNT   = PRIMARIES_AVAILABLE - PRIMARIES_3_COUNT
      MIN_4_PRIMARY       = MIN_PRIMARY + PRIMARIES_3_COUNT
      MIN_4_BOUNDARY      = PRIMARIES_3_COUNT * THREE_BYTE_COUNT

      TOTAL_NEEDED            = MAX_INPUT - MIN_4_BOUNDARY
      NEEDED_PER_PRIMARY_BYTE = (TOTAL_NEEDED - 1) / PRIMARIES_4_COUNT + 1
      NEEDED_PER_FINAL_BYTE   = (NEEDED_PER_PRIMARY_BYTE - 1) / (MEDIAL_COUNT * MEDIAL_COUNT) + 1

      GAP_4 = (MAX_TRAIL - MIN_TRAIL - 1) / NEEDED_PER_FINAL_BYTE

      FINAL_4_MULTIPLIER = GAP_4 + 1
      FINAL_4_COUNT      = NEEDED_PER_FINAL_BYTE

      # CJK constants

      NON_CJK_OFFSET = 0x110000

      CJK_COMPAT_USED_BASE  = 0xFA0E
      CJK_COMPAT_USED_LIMIT = 0xFA2F + 1

      CJK_BASE    = 0x4E00        # 4E00;<CJK Ideograph, First>;Lo;0;L;;;;;N;;;;;
      CJK_LIMIT   = 0x9FCC + 1    # 9FCC;<CJK Ideograph, Last>;Lo;0;L;;;;;N;;;;;

      CJK_A_BASE  = 0x3400        # 3400;<CJK Ideograph Extension A, First>;Lo;0;L;;;;;N;;;;;
      CJK_A_LIMIT = 0x4DB5 + 1    # 4DB5;<CJK Ideograph Extension A, Last>;Lo;0;L;;;;;N;;;;;

      CJK_B_BASE  = 0x20000       # 20000;<CJK Ideograph Extension B, First>;Lo;0;L;;;;;N;;;;;
      CJK_B_LIMIT = 0x2A6D6 + 1   # 2A6D6;<CJK Ideograph Extension B, Last>;Lo;0;L;;;;;N;;;;;

      CJK_C_BASE  = 0x2A700       # 2A700;<CJK Ideograph Extension C, First>;Lo;0;L;;;;;N;;;;;
      CJK_C_LIMIT = 0x2B734 + 1   # 2B734;<CJK Ideograph Extension C, Last>;Lo;0;L;;;;;N;;;;;

      CJK_D_BASE  = 0x2B740       # 2B740;<CJK Ideograph Extension D, First>;Lo;0;L;;;;;N;;;;;
      CJK_D_LIMIT = 0x2B81D + 1   # 2B81D;<CJK Ideograph Extension D, Last>;Lo;0;L;;;;;N;;;;;

    end

  end
end