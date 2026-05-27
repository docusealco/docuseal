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

      # The Mac Roman standard encoding for Latin texts.
      #
      # See: PDF2.0 sD.1, sD.2
      class MacRomanEncoding < Base

        def initialize #:nodoc:
          super
          @encoding_name = :MacRomanEncoding
          @code_to_name = {
            0101 => :A,
            0256 => :AE,
            0347 => :Aacute,
            0345 => :Acircumflex,
            0200 => :Adieresis,
            0313 => :Agrave,
            0201 => :Aring,
            0314 => :Atilde,
            0102 => :B,
            0103 => :C,
            0202 => :Ccedilla,
            0104 => :D,
            0105 => :E,
            0203 => :Eacute,
            0346 => :Ecircumflex,
            0350 => :Edieresis,
            0351 => :Egrave,
            0106 => :F,
            0107 => :G,
            0110 => :H,
            0111 => :I,
            0352 => :Iacute,
            0353 => :Icircumflex,
            0354 => :Idieresis,
            0355 => :Igrave,
            0112 => :J,
            0113 => :K,
            0114 => :L,
            0115 => :M,
            0116 => :N,
            0204 => :Ntilde,
            0117 => :O,
            0316 => :OE,
            0356 => :Oacute,
            0357 => :Ocircumflex,
            0205 => :Odieresis,
            0361 => :Ograve,
            0257 => :Oslash,
            0315 => :Otilde,
            0120 => :P,
            0121 => :Q,
            0122 => :R,
            0123 => :S,
            0124 => :T,
            0125 => :U,
            0362 => :Uacute,
            0363 => :Ucircumflex,
            0206 => :Udieresis,
            0364 => :Ugrave,
            0126 => :V,
            0127 => :W,
            0130 => :X,
            0131 => :Y,
            0331 => :Ydieresis,
            0132 => :Z,
            0141 => :a,
            0207 => :aacute,
            0211 => :acircumflex,
            0253 => :acute,
            0212 => :adieresis,
            0276 => :ae,
            0210 => :agrave,
            0046 => :ampersand,
            0214 => :aring,
            0136 => :asciicircum,
            0176 => :asciitilde,
            0052 => :asterisk,
            0100 => :at,
            0213 => :atilde,
            0142 => :b,
            0134 => :backslash,
            0174 => :bar,
            0173 => :braceleft,
            0175 => :braceright,
            0133 => :bracketleft,
            0135 => :bracketright,
            0371 => :breve,
            0245 => :bullet,
            0143 => :c,
            0377 => :caron,
            0215 => :ccedilla,
            0374 => :cedilla,
            0242 => :cent,
            0366 => :circumflex,
            0072 => :colon,
            0054 => :comma,
            0251 => :copyright,
            0333 => :currency,
            0144 => :d,
            0240 => :dagger,
            0340 => :daggerdbl,
            0241 => :degree,
            0254 => :dieresis,
            0326 => :divide,
            0044 => :dollar,
            0372 => :dotaccent,
            0365 => :dotlessi,
            0145 => :e,
            0216 => :eacute,
            0220 => :ecircumflex,
            0221 => :edieresis,
            0217 => :egrave,
            0070 => :eight,
            0311 => :ellipsis,
            0321 => :emdash,
            0320 => :endash,
            0075 => :equal,
            0041 => :exclam,
            0301 => :exclamdown,
            0146 => :f,
            0336 => :fi,
            0065 => :five,
            0337 => :fl,
            0304 => :florin,
            0064 => :four,
            0332 => :fraction,
            0147 => :g,
            0247 => :germandbls,
            0140 => :grave,
            0076 => :greater,
            0307 => :guillemotleft,
            0310 => :guillemotright,
            0334 => :guilsinglleft,
            0335 => :guilsinglright,
            0150 => :h,
            0375 => :hungarumlaut,
            0055 => :hyphen,
            0151 => :i,
            0222 => :iacute,
            0224 => :icircumflex,
            0225 => :idieresis,
            0223 => :igrave,
            0152 => :j,
            0153 => :k,
            0154 => :l,
            0074 => :less,
            0302 => :logicalnot,
            0155 => :m,
            0370 => :macron,
            0265 => :mu,
            0156 => :n,
            0071 => :nine,
            0226 => :ntilde,
            0043 => :numbersign,
            0157 => :o,
            0227 => :oacute,
            0231 => :ocircumflex,
            0232 => :odieresis,
            0317 => :oe,
            0376 => :ogonek,
            0230 => :ograve,
            0061 => :one,
            0273 => :ordfeminine,
            0274 => :ordmasculine,
            0277 => :oslash,
            0233 => :otilde,
            0160 => :p,
            0246 => :paragraph,
            0050 => :parenleft,
            0051 => :parenright,
            0045 => :percent,
            0056 => :period,
            0341 => :periodcentered,
            0344 => :perthousand,
            0053 => :plus,
            0261 => :plusminus,
            0161 => :q,
            0077 => :question,
            0300 => :questiondown,
            0042 => :quotedbl,
            0343 => :quotedblbase,
            0322 => :quotedblleft,
            0323 => :quotedblright,
            0324 => :quoteleft,
            0325 => :quoteright,
            0342 => :quotesinglbase,
            0047 => :quotesingle,
            0162 => :r,
            0250 => :registered,
            0373 => :ring,
            0163 => :s,
            0244 => :section,
            0073 => :semicolon,
            0067 => :seven,
            0066 => :six,
            0057 => :slash,
            0040 => :space,
            0243 => :sterling,
            0164 => :t,
            0063 => :three,
            0367 => :tilde,
            0252 => :trademark,
            0062 => :two,
            0165 => :u,
            0234 => :uacute,
            0236 => :ucircumflex,
            0237 => :udieresis,
            0235 => :ugrave,
            0137 => :underscore,
            0166 => :v,
            0167 => :w,
            0170 => :x,
            0171 => :y,
            0330 => :ydieresis,
            0264 => :yen,
            0172 => :z,
            0060 => :zero,
            # additions due to PDF2.0 sD.2 footnote 6
            0312 => :space,
          }
        end

      end

    end
  end
end
