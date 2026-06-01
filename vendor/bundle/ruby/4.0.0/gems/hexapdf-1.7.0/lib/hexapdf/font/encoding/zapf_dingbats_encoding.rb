# -*- encoding: utf-8; frozen_string_literal: true -*-
#
#--
# This file is part of HexaPDF.
#
# HexaPDF - A Versatile PDF Creation and Manipulation Library For Ruby
# Copyright (C) 2014-2025 Thomas Leitner
#
# HexaPDF is free software: you can redistribute it and/or modify it
# under the terms of the GNU Affero General Public License version 3 as
# published by the Free Software Foundation with the addition of the
# following permission added to Section 15 as permitted in Section 7(a):
# FOR ANY PART OF THE COVERED WORK IN WHICH THE COPYRIGHT IS OWNED BY
# THOMAS LEITNER, THOMAS LEITNER DISCLAIMS THE WARRANTY OF NON
# INFRINGEMENT OF THIRD PARTY RIGHTS.
#
# HexaPDF is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public
# License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with HexaPDF. If not, see <http://www.gnu.org/licenses/>.
#
# The interactive user interfaces in modified source and object code
# versions of HexaPDF must display Appropriate Legal Notices, as required
# under Section 5 of the GNU Affero General Public License version 3.
#
# In accordance with Section 7(b) of the GNU Affero General Public
# License, a covered work must retain the producer line in every PDF that
# is created or manipulated using HexaPDF.
#
# If the GNU Affero General Public License doesn't fit your need,
# commercial licenses are available at <https://gettalong.at/hexapdf/>.
#++

require 'hexapdf/font/encoding/base'

module HexaPDF
  module Font
    module Encoding

      # The built-in encoding of the ZapfDingbats font.
      #
      # See: PDF2.0 sD.6
      class ZapfDingbatsEncoding < Base

        def initialize #:nodoc:
          super
          @code_to_name = {
            0040 => :space,
            0041 => :a1,
            0042 => :a2,
            0043 => :a202,
            0044 => :a3,
            0045 => :a4,
            0046 => :a5,
            0047 => :a119,
            0050 => :a118,
            0051 => :a117,
            0052 => :a11,
            0053 => :a12,
            0054 => :a13,
            0055 => :a14,
            0056 => :a15,
            0057 => :a16,
            0060 => :a105,
            0061 => :a17,
            0062 => :a18,
            0063 => :a19,
            0064 => :a20,
            0065 => :a21,
            0066 => :a22,
            0067 => :a23,
            0070 => :a24,
            0071 => :a25,
            0072 => :a26,
            0073 => :a27,
            0074 => :a28,
            0075 => :a6,
            0076 => :a7,
            0077 => :a8,
            0100 => :a9,
            0101 => :a10,
            0102 => :a29,
            0103 => :a30,
            0104 => :a31,
            0105 => :a32,
            0106 => :a33,
            0107 => :a34,
            0110 => :a35,
            0111 => :a36,
            0112 => :a37,
            0113 => :a38,
            0114 => :a39,
            0115 => :a40,
            0116 => :a41,
            0117 => :a42,
            0120 => :a43,
            0121 => :a44,
            0122 => :a45,
            0123 => :a46,
            0124 => :a47,
            0125 => :a48,
            0126 => :a49,
            0127 => :a50,
            0130 => :a51,
            0131 => :a52,
            0132 => :a53,
            0133 => :a54,
            0134 => :a55,
            0135 => :a56,
            0136 => :a57,
            0137 => :a58,
            0140 => :a59,
            0141 => :a60,
            0142 => :a61,
            0143 => :a62,
            0144 => :a63,
            0145 => :a64,
            0146 => :a65,
            0147 => :a66,
            0150 => :a67,
            0151 => :a68,
            0152 => :a69,
            0153 => :a70,
            0154 => :a71,
            0155 => :a72,
            0156 => :a73,
            0157 => :a74,
            0160 => :a203,
            0161 => :a75,
            0162 => :a204,
            0163 => :a76,
            0164 => :a77,
            0165 => :a78,
            0166 => :a79,
            0167 => :a81,
            0170 => :a82,
            0171 => :a83,
            0172 => :a84,
            0173 => :a97,
            0174 => :a98,
            0175 => :a99,
            0176 => :a100,
            0241 => :a101,
            0242 => :a102,
            0243 => :a103,
            0244 => :a104,
            0245 => :a106,
            0246 => :a107,
            0247 => :a108,
            0250 => :a112,
            0251 => :a111,
            0252 => :a110,
            0253 => :a109,
            0254 => :a120,
            0255 => :a121,
            0256 => :a122,
            0257 => :a123,
            0260 => :a124,
            0261 => :a125,
            0262 => :a126,
            0263 => :a127,
            0264 => :a128,
            0265 => :a129,
            0266 => :a130,
            0267 => :a131,
            0270 => :a132,
            0271 => :a133,
            0272 => :a134,
            0273 => :a135,
            0274 => :a136,
            0275 => :a137,
            0276 => :a138,
            0277 => :a139,
            0300 => :a140,
            0301 => :a141,
            0302 => :a142,
            0303 => :a143,
            0304 => :a144,
            0305 => :a145,
            0306 => :a146,
            0307 => :a147,
            0310 => :a148,
            0311 => :a149,
            0312 => :a150,
            0313 => :a151,
            0314 => :a152,
            0315 => :a153,
            0316 => :a154,
            0317 => :a155,
            0320 => :a156,
            0321 => :a157,
            0322 => :a158,
            0323 => :a159,
            0324 => :a160,
            0325 => :a161,
            0326 => :a163,
            0327 => :a164,
            0330 => :a196,
            0331 => :a165,
            0332 => :a192,
            0333 => :a166,
            0334 => :a167,
            0335 => :a168,
            0336 => :a169,
            0337 => :a170,
            0340 => :a171,
            0341 => :a172,
            0342 => :a173,
            0343 => :a162,
            0344 => :a174,
            0345 => :a175,
            0346 => :a176,
            0347 => :a177,
            0350 => :a178,
            0351 => :a179,
            0352 => :a193,
            0353 => :a180,
            0354 => :a199,
            0355 => :a181,
            0356 => :a200,
            0357 => :a182,
            0361 => :a201,
            0362 => :a183,
            0363 => :a184,
            0364 => :a197,
            0365 => :a185,
            0366 => :a194,
            0367 => :a198,
            0370 => :a186,
            0371 => :a195,
            0372 => :a187,
            0373 => :a188,
            0374 => :a189,
            0375 => :a190,
            0376 => :a191,
          }
        end

        # The ZapfDingbats font uses a special glyph list, so we need to specialize this method.
        #
        # See: Encoding#unicode
        def unicode(code)
          @unicode_cache[code] ||= GlyphList.name_to_unicode(name(code), zapf_dingbats: true)
        end

      end

    end
  end
end
